# frozen_string_literal: true

require "test_helper"
require "autoload_reloadable/active_support_ext"

module AutoloadReloadable
  class ActiveSupportExtTest < Minitest::Test
    def setup
      @tmpdir = Dir.mktmpdir
      @top_level_constants = Object.constants
      @old_loaded_features = $LOADED_FEATURES.dup
    end

    def teardown
      ActiveSupport::Dependencies.clear
      ActiveSupport::Dependencies.autoload_paths = []
      ActiveSupport::Dependencies.autoload_once_paths = []
      FileUtils.remove_entry(@tmpdir)
      assert_equal [], Object.constants - @top_level_constants
      assert_equal [], $LOADED_FEATURES - @old_loaded_features
    end

    def test_autoload_paths_set
      ActiveSupport::Dependencies.autoload_paths = [@tmpdir]
      assert_equal [@tmpdir], AutoloadReloadable::Paths.to_a
    end

    def test_autoload_paths_push
      dirs = %w(a b).map { |name| File.join(@tmpdir, name) }
      dirs.each do |dirname|
        Dir.mkdir(dirname)
        ActiveSupport::Dependencies.autoload_paths.push(dirname)
      end
      assert_equal dirs, AutoloadReloadable::Paths.to_a
    end

    def test_autoload_paths_unshift
      dirs = %w(a b).map { |name| File.join(@tmpdir, name) }
      dirs.each do |dirname|
        Dir.mkdir(dirname)
        ActiveSupport::Dependencies.autoload_paths.unshift(dirname)
      end
      assert_equal dirs.reverse, AutoloadReloadable::Paths.to_a
    end

    def test_autoload_paths_map!
      dir_a = File.join(@tmpdir, 'a')
      dir_b = File.join(@tmpdir, 'b')
      Dir.mkdir(dir_a)
      Dir.mkdir(dir_b)
      ActiveSupport::Dependencies.autoload_paths << dir_a
      ActiveSupport::Dependencies.autoload_paths.map! { |dir| dir_b if dir == dir_a }
      assert_equal [dir_b], AutoloadReloadable::Paths.to_a
    end

    def test_autoload_paths_push_after_set_to_new_array
      paths = ActiveSupport::Dependencies.autoload_paths
      paths << @tmpdir
      ActiveSupport::Dependencies.autoload_paths = paths.dup
      paths << File.join(Dir.tmpdir)
      assert_equal [@tmpdir], AutoloadReloadable::Paths.to_a
    end

    def test_inflector
      ActiveSupport::Inflector.inflections.acronym('API')
      File.write(File.join(@tmpdir, "foos_api.rb"), "class FoosAPI; end")
      ActiveSupport::Dependencies.autoload_paths << @tmpdir
      assert_equal File.join(@tmpdir, "foos_api.rb"), Object.autoload?(:FoosAPI)
    end

    def test_clear
      File.write(File.join(@tmpdir, "foo.rb"), "class Foo; def self.value; 1; end; end")
      ActiveSupport::Dependencies.autoload_paths << @tmpdir
      assert_equal 1, Foo.value
      File.write(File.join(@tmpdir, "foo.rb"), "class Foo; def self.value; 2; end; end")
      ActiveSupport::Dependencies.clear
      assert_equal 2, Foo.value
    end

    def test_autoload_once_paths
      filename = File.join(@tmpdir, "foo.rb")
      File.write(filename, "class Foo; def self.value; 1; end; end")
      ActiveSupport::Dependencies.autoload_paths << @tmpdir
      ActiveSupport::Dependencies.autoload_once_paths << @tmpdir
      assert_equal 1, Foo.value
      File.write(filename, "class Foo; def self.value; 2; end; end")
      ActiveSupport::Dependencies.clear
      assert_equal 1, Foo.value
      assert $LOADED_FEATURES.include?(filename)
    ensure
      Object.send(:remove_const, :Foo) if defined?(::Foo)
      $LOADED_FEATURES.delete(filename)
    end

    def test_no_const_missing_hook
      filename = File.join(@tmpdir, "foo.rb")
      File.write(filename, "class Foo; end")
      ActiveSupport::Dependencies.autoload_paths << @tmpdir
      assert_raises(NameError, 'uninitialized constant Foo') do
        Object.const_missing('Foo')
      end
      assert_equal filename, Object.autoload?(:Foo)
    end

    def test_unhook!
      filename = File.join(@tmpdir, "foo.rb")
      File.write(filename, "class Foo; end")
      ActiveSupport::Dependencies.autoload_paths << @tmpdir
      pid = fork do
        assert_equal filename, Object.autoload?(:Foo)
        ActiveSupport::Dependencies.unhook!
        assert_nil Object.autoload?(:Foo)
        assert_nil defined?(::Foo)
        assert_equal [], AutoloadReloadable::Paths.to_a
        ActiveSupport::Dependencies.autoload_paths << @tmpdir
        assert_equal [], AutoloadReloadable::Paths.to_a
        ActiveSupport::Dependencies.autoload_paths = [@tmpdir]
        assert_equal [], AutoloadReloadable::Paths.to_a

        # exit!(true) the process to get around fork issues on minitest 5
        # see https://github.com/seattlerb/minitest/issues/467
        Process.exit!(true)
      end
      Process.wait(pid)
      assert_equal true, $?.success?
    end

    def test_require_dependency
      filename = File.join(@tmpdir, "foo.rb")
      File.write(filename, "class Foo; end")
      ActiveSupport::Dependencies.autoload_paths << @tmpdir
      require_dependency 'foo'
      assert defined?(::Foo)
      assert_nil Object.autoload?(:Foo)
      assert $LOADED_FEATURES.include?(filename)
    end
  end
end
