# frozen_string_literal: true

require 'active_support/inflector'
require 'active_support/dependencies'
require 'autoload_reloadable'

module AutoloadReloadable
  module PathsSync
    AutoloadReloadable.private_constant :PathsSync

    class << self
      attr_reader :autoload_paths

      def extended(autoload_paths)
        unless @disabled
          Paths.replace(autoload_paths)
          @autoload_paths = autoload_paths
        end
        super
      end

      def disable
        @disabled = true
        @autoload_paths = nil
      end
    end
    @disabled = false

    %i(<< push unshift prepend concat clear replace).each do |method_name|
      define_method(method_name) do |*args|
        if PathsSync.autoload_paths.equal?(self)
          Paths.public_send(method_name, *args)
        end
        super(*args)
      end
    end

    %i(
      []= collect! compact! delete delete_at delete_if fill flatten!
      insert keep_if map! pop reject! reverse! rotate! select!
      shift shuffle! slice! sort! uniq!
    ).each do |method_name|
      define_method(method_name) do |*args, &block|
        ret = super(*args, &block)
        if PathsSync.autoload_paths.equal?(self)
          Paths.replace(self)
        end
        ret
      end
    end
  end

  module DependenciesExt
    AutoloadReloadable.private_constant :DependenciesExt

    def autoload_paths=(paths)
      super
      paths.extend(PathsSync)
      paths
    end

    def autoload_once_paths=(paths)
      AutoloadReloadable.non_reloadable_paths = super
    end

    def clear
      ret = super
      AutoloadReloadable.reload
      ret
    end

    def unhook!
      PathsSync.disable
      AutoloadReloadable::Paths.clear
      super
    end

    # AutoloadReloadable always uses `require` for autoloading
    def load?
      false
    end

    # require_dependency uses an expanded file path that doesn't
    # resolve symlinks, so links in the autoload path can cause
    # it to load a different absolute filename than using require
    # with a relative path. Using File.realpath on the load path
    # when it is also done in ruby will avoid a mismatch in
    # Autoloads.around_require when trying to detect an autoload
    # is loaded using a hash lookup of the filename.
    if Autoloads::REAL_LOAD_PATHS
      def search_for_file(path_suffix)
        path_suffix = path_suffix.sub(/(\.rb)?$/, ".rb".freeze)
        path = super(path_suffix)
        if path && path.end_with?(path_suffix)
          load_path = path.slice(0, path.length - path_suffix.length)
          load_path = File.realpath(load_path)
          path = File.join(load_path, path_suffix)
        end
        path
      end
    end
  end

  self.inflector = ActiveSupport::Inflector
  self.non_reloadable_paths = ActiveSupport::Dependencies.autoload_once_paths

  ActiveSupport::Dependencies.autoload_paths.extend(PathsSync)
  ActiveSupport::Dependencies.singleton_class.prepend(DependenciesExt)

  Module.class_eval do
    if original_const_missing = @_const_missing
      ActiveSupport::Dependencies::ModuleConstMissing.exclude_from(self)
      @_const_missing = original_const_missing
    end
  end
end
