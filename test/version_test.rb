# frozen_string_literal: true
require "test_helper"

module AutoloadReloadable
  class VersionTest < Minitest::Test
    def test_version
      assert_equal ::AutoloadReloadable::VERSION, Gem::Version.new(::AutoloadReloadable::VERSION).to_s
    end
  end
end
