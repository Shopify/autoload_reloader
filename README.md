# AutoloadReloadable

An alternative to the rails autoloader (ActiveSupport::Dependencies)
that is based on Module#autoload instead of const_missing.

## Installation

Add this line to your application's Gemfile
to use it by itself

```ruby
gem 'autoload_reloadable'
```

Or add this line to the application's Gemfile to replace
the const_missing based autoloading in rails' activesupport gem.

```
gem 'autoload_reloadable', require: 'autoload_reloadable/active_support_ext'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install autoload_reloadable

## Usage

This library can be used by itself as follows

```ruby
require 'autoload_reloadable'

File.write "foo.rb", "Foo = 1"

# sets up autoloads by scanning the file system
AutoloadReloadable::Paths.push(Dir.pwd)

# start using autoloaded constants
Foo # => 1

File.write "foo.rb", "Foo = 2"

# unload constants and re-scan paths to autoload them again
AutoloadReloadable.reload
Foo # => 2

# load all autoloadable constants in the paths
AutoloadReloadable.eager_load
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dylanahsmith/autoload_reloadable.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
