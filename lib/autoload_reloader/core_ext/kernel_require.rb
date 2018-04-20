module AutoloadReloader # to access it's private constants
  module ::Kernel
    module_function

    alias_method :require_without_autoload_reloader, :require
    def require(path)
      Autoloads.around_require(path) do
        require_without_autoload_reloader(path)
      end
    end
  end
end
