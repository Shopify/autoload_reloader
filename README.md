# AutoloadReloadable

An alternative to the rails autoloader (ActiveSupport::Dependencies)
that is based on Module#autoload instead of const_missing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'autoload_reloadable'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install autoload_reloadable

## Usage

```ruby
require 'autoload_reloadable'

# sets up autoloads by scanning the file system
AutoloadReloadable.push_paths([__dir__])

# start using autoloaded constants
Foo.bar # Foo autoloaded from "#{__dir__}/foo.rb"

# unload constants and re-scan paths to autoload them again
AutoloadReloadable.reload

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
