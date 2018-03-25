# frozen_string_literal: true

require "autoload_reloadable/version"
require "autoload_reloadable/ruby_backports"
require "autoload_reloadable/constant_reference"
require "autoload_reloadable/autoloads"
require "autoload_reloadable/unloaded_namespaces"
require "autoload_reloadable/loaded"
require "autoload_reloadable/paths"
require "autoload_reloadable/core_ext/kernel_require"

module AutoloadReloadable
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

  autoload :BasicInflector, "autoload_reloadable/basic_inflector"

  def self.inflector
    @inflector ||= begin
      if defined?(ActiveSupport::Inflector)
        ActiveSupport::Inflector
      else
        BasicInflector
      end
    end
  end

  class << self
    attr_writer :inflector
  end
end
