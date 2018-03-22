# frozen_string_literal: true

module AutoloadReloadable
  module Paths
    AutoloadReloadable.private_constant :Paths

    class << self
      attr_accessor :paths
    end
    self.paths = []

    def self.add_paths(paths, prepend: false)
      return if paths.empty?
      expanded_paths = paths.map { |path| File.expand_path(path) }
      if prepend
        self.paths.unshift(expanded_paths)
      else
        self.paths.concat(expanded_paths)
      end
      expanded_paths.each do |path|
        Autoloads.add_from_path(path, prepend: prepend)
      end
    end

    def self.clear
      paths.clear
      Autoloads.remove_all
    end

    def self.reload
      Loaded.unload_all
      Autoloads.remove_all
      paths.each do |path|
        Autoloads.add_from_path(path)
      end
    end
  end
end
