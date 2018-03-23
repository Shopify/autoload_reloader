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
  def self.push_paths(paths)
    Paths.add_paths(paths)
  end

  def self.prepend_paths(paths)
    Paths.add_paths(paths, prepend: true)
  end

  def self.clear_paths
    Paths.clear
  end

  def self.replace_paths(paths)
    clear_paths
    Paths.add_paths(paths)
  end

  def self.reload
    Paths.reload
  end

  def self.eager_load
    Autoloads.eager_load
  end

  def self.module_defined(mod)
    UnloadedNamespaces.loaded(mod)
  end

  def self.clear
    Loaded.unload_all
    clear_paths
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
