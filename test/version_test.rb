# frozen_string_literal: true
require "test_helper"

module AutoloadReloader
  class VersionTest < Minitest::Test
    def test_version
      assert_equal ::AutoloadReloader::VERSION, Gem::Version.new(::AutoloadReloader::VERSION).to_s
    end
  end
end
