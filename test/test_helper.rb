# frozen_string_literal: true

unless ENV['USE_BOOTSNAP'].to_s.empty?
  require 'bootsnap'
  Bootsnap.setup(
    cache_dir:            'tmp/cache',
    development_mode:     true,
    load_path_cache:      true,
    autoload_paths_cache: true,
    disable_trace:        false,
    compile_cache_iseq:   false,
    compile_cache_yaml:   false
  )
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "autoload_reloader"
require "tempfile"
if RUBY_ENGINE == 'ruby'
  require "byebug"
end

require "minitest/autorun"
