# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "autoload_reloadable"
require "tempfile"
if RUBY_ENGINE == 'ruby'
  require "byebug"
end

require "minitest/autorun"
