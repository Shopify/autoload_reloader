# frozen_string_literal: true
require "test_helper"

module AutoloadReloadable
  class VersionTest < Minitest::Test
    def test_that_it_has_a_version_number
      refute_nil ::AutoloadReloadable::VERSION
    end
  end
end
