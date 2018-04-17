# frozen_string_literal: true

require 'tmpdir'

module AutoloadReloader
  using RubyBackports

  module Autoloads
    AutoloadReloader.private_constant :Autoloads

    CONST_NAME_REGEX = /\A[A-Z][\w_]*\z/

    class << self
      attr_accessor :const_ref_by_filename
    end
    self.const_ref_by_filename = {}

    def self.add_from_path(path, parent: Object, parent_name: nil, prepend: false, path_root: path)
      unless File.directory?(path)
        warn "[AutoloadReloader] Warning: Autoload path directory not found: #{path}"
        return
      end
      expanded_path = expanded_load_path(path)
      Dir.each_child(expanded_path) do |filename|
        expanded_filename = File.join(expanded_path, filename)
        basename = File.basename(filename, ".rb")
        const_name = AutoloadReloader.inflector.camelize(basename)
        next unless CONST_NAME_REGEX.match?(const_name)
        const_name = const_name.to_sym
        autoload_filename = parent.autoload?(const_name)
        loaded = !autoload_filename && parent.const_defined?(const_name, false)
        full_const_name = (parent_name.nil? ? const_name.to_s : "#{parent_name}::#{const_name}").freeze

        if filename.end_with?(".rb")
          next if loaded
          if autoload_filename
            const_ref = const_ref_by_filename[autoload_filename]
            next unless const_ref # autoload wasn't defined by this gem
            unless const_ref.directory?
              warn "Multiple paths to autoload #{full_const_name}:\n  #{autoload_filename}\n  #{expanded_filename}"
              next unless prepend
            end
            remove(const_ref)
          end
          add(ConstantReference.new(parent, const_name, full_const_name, expanded_filename, path_root))
        elsif File.directory?(expanded_filename)
          if loaded
            mod = parent.const_get(const_name)
            add_from_path(expanded_filename, parent: mod, parent_name: full_const_name, prepend: prepend, path_root: path_root)
          else
            unless autoload_filename
              add(ConstantReference.new(parent, const_name, full_const_name, expanded_filename, path_root))
            end
            UnloadedNamespaces.add_constants_from_path(
              expanded_filename,
              parent_name: full_const_name,
              prepend: prepend,
              path_root: path_root,
            )
          end
        end
      end
    end

    def self.define_module_trace
      @define_module_trace ||= TracePoint.new(:class) do |tp|
        defined_module = tp.self
        UnloadedNamespaces.loaded(defined_module)
      end
    end

    def self.add(const_ref)
      if const_ref_by_filename.empty?
        define_module_trace.enable
      end
      const_ref_by_filename[const_ref.filename] = const_ref
      const_ref.parent.autoload(const_ref.name, const_ref.filename)
    end

    def self.remove(const_ref)
      const_ref.parent.send(:remove_const, const_ref.name)
      const_ref_by_filename.delete(const_ref.filename)
    end

    def self.loaded(filename)
      if const_ref = const_ref_by_filename.delete(filename)
        mod = const_ref.parent.const_get(const_ref.name)
        unless AutoloadReloader.non_reloadable_paths.include?(const_ref.path_root)
          Loaded.add_reloadable(const_ref)
        end
        UnloadedNamespaces.loaded(mod, mod_name: const_ref.full_const_name)
        if const_ref_by_filename.empty?
          define_module_trace.disable
        end
      end
    end

    def self.remove_all
      UnloadedNamespaces.remove_all
      const_ref_by_filename.each_value do |const_ref|
        next unless const_ref.parent.autoload?(const_ref.name) == const_ref.filename
        const_ref.parent.send(:remove_const, const_ref.name)
      end
      const_ref_by_filename.clear
      define_module_trace.disable
    end

    def self.eager_load
      while pair = const_ref_by_filename.first
        const_ref = pair[1]
        const_ref.parent.const_get(const_ref.name)
      end
    end

    def self.around_require(filename)
      const_ref = const_ref_by_filename[filename]
      ret = if const_ref && const_ref.directory?
        const_ref.parent.const_set(const_ref.name, Module.new)
        true
      elsif const_ref
        yield
      else
        # require might have been used manually with a relative path
        index = $LOADED_FEATURES.length
        ret = yield
        filename = $LOADED_FEATURES[index]
        ret
      end
      loaded(filename)
      ret
    end

    # MRI Ruby 2.4.4+ get the realpath (i.e. resolve symlinks) when
    # expanding load paths which we need to match so that a manual
    # require can detect that an autoloaded constant was loaded
    # based on the filename in $LOADED_FEATURES in the above require
    # hook loaded uses a hash lookup.
    #
    # Use feature detection since now only does it depend on the ruby
    # version and ruby implementation, but may also depend on the
    # presence of a gem like bootsnap that patches require.
    def self.use_real_load_paths?
      return @use_real_load_paths if defined?(@use_real_load_paths)

      Dir.mktmpdir do |tmp_dir|
        real_load_path = File.join(File.realpath(tmp_dir), "real")
        real_file_path = File.join(real_load_path, "autoload_reloader", "test_feature.rb")
        sym_load_path = File.join(tmp_dir, "sym")
        sym_file_path = File.join(sym_load_path, "autoload_reloader", "test_feature.rb")
        FileUtils.mkdir_p(File.dirname(real_file_path))
        begin
          File.symlink(real_load_path, sym_load_path)
        rescue NotImplementedError
          @use_real_load_paths = false
          return false
        end
        File.write(real_file_path, "")
        $LOAD_PATH << sym_load_path
        require "autoload_reloader/test_feature"
        $LOAD_PATH.delete(sym_load_path)
        @use_real_load_paths = if $LOADED_FEATURES.delete(real_file_path)
          true
        elsif $LOADED_FEATURES.delete(sym_file_path)
          false
        else
          raise "failed to map required file to loaded feature"
        end
      end
    end

    def self.expanded_load_path(path)
      if use_real_load_paths?
        File.realpath(path)
      else
        File.expand_path(path)
      end
    end
  end
end
