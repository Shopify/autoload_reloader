# frozen_string_literal: true

module AutoloadReloadable
  module RubyBackports
    AutoloadReloadable.private_constant :RubyBackports

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.5')
      PARENT_AND_CURRENT_DIR = ['.', '..']

      refine Dir.singleton_class do
        def each_child(dirname)
          Dir.foreach(dirname) do |filename|
            yield filename unless PARENT_AND_CURRENT_DIR.include?(filename)
          end
        end
      end
    end

    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.4')
      refine Regexp do
        def match?(str)
          (self =~ str) != nil
        end
      end
    end
  end
end

