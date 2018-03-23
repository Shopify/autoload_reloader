# frozen_string_literal: true

module AutoloadReloadable
  using RubyBackports

  module UnloadedNamespaces
    AutoloadReloadable.private_constant :UnloadedNamespaces

    class << self
      attr_accessor :nested_autoloads
    end
    self.nested_autoloads = {}

    def self.loaded(mod)
      nested = nested_autoloads.delete(mod.name)
      return unless nested
      nested.each_value do |constant_reference|
        constant_reference.parent = mod
        Autoloads.add(constant_reference)
      end
    end

    def self.add_constants_from_path(expanded_path, parent_name:, prepend:, path_root:)
      autoloads = self.nested_autoloads[parent_name] ||= {}
      Dir.each_child(expanded_path) do |filename|
        expanded_filename = File.join(expanded_path, filename)
        basename = File.basename(filename, ".rb")
        const_name = AutoloadReloadable.inflector.classify(basename).to_sym
        const_ref = autoloads[const_name]

        if filename.end_with?(".rb")
          if const_ref
            unless const_ref.directory?
              warn "Multiple paths to autoload #{parent_name}::#{const_name}:\n  #{const_ref.filename}\n  #{expanded_filename}"
              next unless prepend
            end
            autoloads.delete(const_name)
          end
          autoloads[const_name] = ConstantReference.new(nil, const_name, expanded_filename, path_root)
        elsif File.directory?(expanded_filename)
          unless const_ref
            autoloads[const_name] = ConstantReference.new(nil, const_name, expanded_filename, path_root)
          end
          add_constants_from_path(
            expanded_filename,
            parent_name: "#{parent_name}::#{const_name}",
            prepend: prepend,
            path_root: path_root,
          )
        end
      end
    end

    def self.remove_all
      nested_autoloads.clear
    end
  end
end
