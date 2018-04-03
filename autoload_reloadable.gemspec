
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "autoload_reloadable/version"

Gem::Specification.new do |spec|
  spec.name          = "autoload_reloadable"
  spec.version       = AutoloadReloadable::VERSION
  spec.authors       = ["Dylan Thacker-Smith"]
  spec.email         = ["Dylan.Smith@shopify.com"]

  spec.summary       = "Autoload and reload constants in path using Module#autoload"
  spec.homepage      = "https://github.com/dylanahsmith/autoload_reloadable"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3.0"

  spec.add_development_dependency "activesupport", ">= 4.2"
  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  if RUBY_ENGINE == 'ruby'
    spec.add_development_dependency "byebug"
  end
end
