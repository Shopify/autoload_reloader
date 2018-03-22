# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "autoload_reloadable"
require "tempfile"
if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("2.2")
  require "byebug"
end

require "minitest/autorun"
