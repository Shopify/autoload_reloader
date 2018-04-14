# frozen_string_literal: true

require "autoload_reloader/version"
require "autoload_reloader/ruby_backports"
require "autoload_reloader/constant_reference"
require "autoload_reloader/autoloads"
require "autoload_reloader/unloaded_namespaces"
require "autoload_reloader/loaded"
require "autoload_reloader/paths"
require "autoload_reloader/core_ext/kernel_require"
require "set"

module AutoloadReloader
  def self.reload
    Loaded.unload_all
    Paths.replace(Paths.to_a)
  end

  def self.eager_load
    Autoloads.eager_load
  end

  def self.module_defined(mod)
    UnloadedNamespaces.loaded(mod)
  end

  def self.clear
    Loaded.unload_all
    Paths.clear
  end

  autoload :BasicInflector, "autoload_reloader/basic_inflector"

  def self.inflector
    @inflector ||= BasicInflector
  end

  class << self
    attr_writer :inflector
    attr_accessor :non_reloadable_paths
  end

  @non_reloadable_paths = Set.new
end
