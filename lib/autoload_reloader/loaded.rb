# frozen_string_literal: true

module AutoloadReloader
  module Loaded
    AutoloadReloader.private_constant :Loaded

    class << self
      attr_accessor :reloadable
    end
    self.reloadable = []

    def self.add_reloadable(constant_reference)
      reloadable << constant_reference
    end

    def self.unload_all
      unloaded_features = Set.new
      reloadable.each do |ref|
        ref.parent.send(:remove_const, ref.name)
        unloaded_features << ref.filename
      end
      $LOADED_FEATURES.reject! do |feature|
        unloaded_features.include?(feature)
      end
      reloadable.clear
      nil
    end
  end
end
