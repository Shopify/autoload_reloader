# AutoloadReloader

An alternative to the rails autoloader (ActiveSupport::Dependencies)
that is based on Module#autoload instead of const_missing.  As the
[Rails Autoloading and Reloading Constants
](http://guides.rubyonrails.org/v5.1/autoloading_and_reloading_constants.html)
guide admits:

> An implementation based on `Module#autoload` would be awesome

## Installation

Add this line to your application's Gemfile
to use it by itself

```ruby
gem 'autoload_reloader', github: 'Shopify/autoload_reloader'
```

Or add this line to the application's Gemfile to replace
the const_missing based autoloading in rails' activesupport gem.

```
gem 'autoload_reloader', github: 'Shopify/autoload_reloader', require: 'autoload_reloader/active_support_ext'
```

And then execute:

    $ bundle

## Usage

This library can be used by itself as follows

```ruby
require 'autoload_reloader'

File.write "foo.rb", "Foo = 1"

# sets up autoloads by scanning the file system
AutoloadReloader::Paths.push(Dir.pwd)

# start using autoloaded constants
Foo # => 1

File.write "foo.rb", "Foo = 2"

# unload constants and re-scan paths to autoload them again
AutoloadReloader.reload
Foo # => 2

# load all autoloadable constants in the paths
AutoloadReloader.eager_load
```

## How It Works

The [Module#autoload isn't Involved
](http://guides.rubyonrails.org/v5.1/autoloading_and_reloading_constants.html#module-autoload-isn-t-involved)
section of the Rails Autoloading and Reloading Constants guide
makes it sound like this gem shouldn't work

> An implementation based on `Module#autoload` would be awesome
> but, as you see, at least as of today it is not possible.

so let's dispell some myths and explain how this gem works.

When the paths are changed through Array like methods on
`AutoloadReloader::Paths`, this gem walks the file system as
the rails guide suggested

> One possible implementation based on `Module#autoload` would be to walk the
> application tree and issue `autoload` calls that map existing file names to
> their conventional constant name.

So let's start addressing the problems previously ran into with this approach

> There are a number of reasons that prevent Rails from using that implementation.
>
> For example, `Module#autoload` is only capable of loading files using `require`,
> so reloading would not be possible.

`require` will load a file again if the file's path is removed from `$LOADED_FEATURES`,
so this is done when `AutoloadReloader.reload` is called.

> Not only that, it uses an internal `require` which is not `Kernel#require`.

This was true before MRI ruby 2.3.0, but [it was changed
](https://github.com/ruby/ruby/commit/cdc251c695f1ab7427f6213187cc447d118f39d9)
to use a [normal ruby `require` method call
](https://github.com/ruby/ruby/blob/v2_3_0/variable.c#L2091-L2092), so
`Kernel#require` can be wrapped to hook into constant autoloading
through `Module#autoload`.

> Then, it provides no way to remove declarations in case a file is deleted.

A constant is considered defined (in a special autoload state) after
using `Module#autoload` before the file itself it loaded, so the
autoload can be removed using `Module#remove_const` when the file
is deleted.

> If a constant gets removed with `Module#remove_const` its `autoload`
> is not triggered again.

Ruby doesn't keep track of the autoload after the constant is loaded,
so `Module#autoload` must be used again after removing the constant for
reloading.

> Also, it doesn't support qualified names, so files with namespaces should
> be interpreted during the walk tree to install their own `autoload` calls, but
> those files could have constant references not yet configured.

Since we can't register autoloads under an autoload namespace with `Module#autoload`,
this gem keeps track of the autoloads under an unloaded namespace to register when
that namespace is loaded.

A [TracePoint](http://ruby-doc.org/core-2.5.0/TracePoint.html) for the `:class` event
is used to detect namespace loaded using the `module` or `class` keywords. This
TracePoint will miss constants defined using `Class.new` or `Module.new` that are
assigned as a constant, in which case this gem detects that the constant is loaded
at the end of the `require` for that constant using this gem's `require` wrapper.

## Why is using Module#autoload awesome compared to const_missing

Using Module#autoload avoids several [common gotchas from using const_missing
](http://guides.rubyonrails.org/v5.1/autoloading_and_reloading_constants.html#common-gotchas).

In general, using `const_missing` leads to various forms of load dependent code
when using namespaced code.

### Avoid Accidentally using a Constant in a Parent Namespace

For example, if you have the code

```ruby
module Admin
  class UsersController < ApplicationController
    def index
      @users = User.all
    end
  end
end
```

and there are autoloadable `::User` and `::Admin::User` constants,
then without using `Module#autoload`, the code would use `::User` if
it has been loaded and `::Admin::User` has not yet been loaded.

This isn't a problem with `Module#autoload`, because ruby finds the
`::Admin::User` constant when doing the constant resolution and
autoloads the constant rather than using `::User`.

Rails recommends using a qualified constant reference (`Admin::User`
in this case) to avoid the ambiguity, but failing to do so results
in subtle load order dependent bug. Qualified constant references
also don't work well with constant privacy.

### Works with Constant Privacy

When a constant with the same name is in a namespace and a parent
namespace, then Rails recommends to use a qualified constant
to avoid accidentally using the constant in the parent namespace.
However, this doesn't work if the constant in the inner namespace
is a private constant, because it is internal to that inner namespace.

For example, you may make `Admin::User` private

```ruby
module Admin
  class User < ApplicationRecord
  end
  private_constant :User
end
```

but now the code

```ruby
module Admin
  class UsersController < ApplicationController
    def index
      @users = Admin::User.all
    end
  end
end
```

will get a `NameError: private constant Admin::User referenced` error
from the constant reference `Admin::User` if `Admin::User` is already
loaded, since ruby prevents private constants from being referenced
in this way.

When using this gem, `Admin::User.all` will consistently get the
above mentioned NameError and can simply be replaced with `User.all`
and it will work reliably.

When using Rails' `const_missing` based autoloader, `Admin::User`
reference would work the first time if neither `::User` nor `Admin::User`
were already loaded, regardless of the namespace it is called from,
since `const_missing` doesn't know how the constant was referenced.
This differing behaviour on first use adds extra developer confusion.
The next time it comes to the constant reference it will get the
above mentioned NameError, but then it can't be fixed by changing
the code to `User.all` since that could end up doing `::User.all`
if `::User` has been loaded by `Admin::User` hasn't.

### Always Respects Module Nesting

Ruby relative constant resolution works by looking for the named
constant directly under each module in `Module.nesting`, which
is affected by the nesting from `module` or `class` keywords.

For example,

```ruby
module Admin
  class UsersTest < ActiveSupport::TestCase
    Module.nesting # => [Admin::UsersTest, Admin]
    test "new" do
      assert User.new
    end
  end
end
```

would use Admin::User if it were defined and Admin::UsersTest::User
weren't also defined, but the following code

```ruby
class Admin::UsersTest < ActiveSupport::TestCase
  Module.nesting # => [Admin::UsersTest]
  test "new" do
    assert User.new
  end
end
```

would not look for Admin::User in ruby's constant resolution since the
only constant opened with `class` or `module` is Admin::UsersTest.

`const_missing` can't use `Module.nesting` to reproduce ruby's
algorithm since it would return the nesting for the code in
`const_missing` rather than the code referencing the constant before
`const_missing` was called.  As such, rails assumes and recommends
the former style is used, so `const_missing` would return `Admin::User`
even in the latter case inside `class Admin::UserTest`.

### Avoid Preventing Autoload by Opening a Namespace

When autoloading based on `const_missing`, opening
a namespace can define a constant and prevent it from
being autoloaded.

For example, by following the Rails recommendation on using nested
namespaces in tests can lead to code like

```ruby
require 'test_helper'

module Admin
  class UsersTest < ActiveSupport::TestCase
    # ...
  end
end
```

If there were an admin.rb file on the autoload path, then loading
the above test file with the Rails' autoloader would cause `module
Admin` to define the constant and the `Admin` constant would never
be missing to load admin.rb through `const_missing`.

In contrast, with Module#autoload based autoloading, ruby
will autoload admin.rb when encoutering `module Admin`
then will re-open the constant defined in admin.rb.

### Works with `require`

Rails warns you to never `require` an autoloaded constant, since
it prevents the constant from being reloaded. This isn't a problem
with this gem. If you want to require a file without an absolute
path (e.g. `require 'user'`) you simply need to make sure it can
be found on the $LOAD_PATH which isn't done automatically by using
`AutoloadReloader::Paths` but is done for autoload paths in rails.

With this gem's Active Support integration, `require_dependency`
is supported for compatibility, but can be safely replaced with
`require` where still needed (e.g. for [Single Table Inheritance
](http://guides.rubyonrails.org/v5.1/autoloading_and_reloading_constants.html#autoloading-and-sti)).

## Limitations

There are some limitations of this gem to be aware of.

### Non-MRI Ruby Implementation Support

Although MRI no longer uses an internal require to load autoload
constants, other ruby implementations still appear to use an
internal require as older version of MRI ruby did.

I have noticed this internal require autoload behaviour for:

* JRuby 9.1.16.0 (although support is [on the way][jruby])
* Rubinius 3.100
* TruffleRuby 0.33

[jruby]: https://github.com/jruby/jruby/issues/5403

### Non-CamelCased Constants

The Rails' autoloader infers the filename from the constant name
(using `String#underscore`) so is able to work with UPPER_CASE named
constants.

In contrast, this gem infers the constant name from the filename, so
filenames like foo_bar.rb should always define FooBar and not FOO_BAR.
This seems fine in practice though, since module and class naming
convention is already to use CamelCase and value constants are
generally too small to merit their own file. If this is problem in
practice, then please open an issue describing the use case.

### Nested References in File Assigning Namespace Constant

For example, if the autoloaded foo.rb file contains

```ruby
Foo = Module.new
Foo.module_eval do
  Foo::Bar
  # ...
end
```

then it won't have a chance to setup autoloads on the Foo namespace
before Foo::Bar is referenced. This is because `Foo = Module.new`
doesn't trigger a `:class` TracePoint event. Using `module Foo` to
define the namespace avoids this problem.

However, this is a contrived example, so if you have a real example
then please open an issue describing the use case.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake test` to run the tests. You can also run `bin/console`
for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake
install`. To release a new version, update the version number in
`version.rb`, and then run `bundle exec rake release`, which will
create a git tag for the version, push git commits and tags, and
push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/Shopify/autoload_reloader.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
