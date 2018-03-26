# frozen_string_literal: true

module AutoloadReloadable
  module BasicInflector
    def self.camelize(underscore_name)
      underscore_name.split('_').map(&:capitalize).join
    end
  end
end
