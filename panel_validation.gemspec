# -*- encoding: utf-8 -*-
require File.expand_path('../lib/panel_validation/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Hogan Yuan"]
  gem.email         = ["wuxsoft@gmail.com"]
  gem.description   = %q{WS Security XML signer}
  gem.summary       = gem.description
  gem.homepage      = ""

  gem.files         = Dir.glob("lib/**/*") + %w(README.md CHANGELOG.md LICENSE)
  gem.executables   = []

  gem.name          = "panel_validation"
  gem.require_paths = ["lib"]
  gem.version       = PanelValidation::VERSION

  gem.required_ruby_version = '>= 2.1.0'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'

  gem.add_runtime_dependency 'nokogiri', '>= 1.5.1'
end
