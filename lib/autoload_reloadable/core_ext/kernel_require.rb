module AutoloadReloadable # to access it's private constants
  module ::Kernel
    alias_method :require_without_autoload_reloadable, :require
    def require(path)
      Autoloads.around_require(path) do
        require_without_autoload_reloadable(path)
      end
    end
  end
end
