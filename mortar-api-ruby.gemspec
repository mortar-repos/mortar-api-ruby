# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "mortar/api/version"

Gem::Specification.new do |gem|
  gem.name    = "mortar-api-ruby"
  gem.version = Mortar::API::VERSION

  gem.author      = "Mortar Data"
  gem.email       = "support@mortardata.com"
  gem.homepage    = "http://mortardata.com/"
  gem.summary     = "Client for Mortar API"
  gem.description = "Client for Mortar API."
  gem.platform    = Gem::Platform::RUBY
  gem.required_ruby_version = '>=1.8.7'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'excon', '~>0.28'

  gem.add_development_dependency 'gem-release'  
  gem.add_development_dependency 'rake'
  gem.add_development_dependency "rr"
  # Use latest 2.x for rspec.  3.x breaks test configuration and various assertions
  gem.add_development_dependency "rspec", '~>2.0'
  
end
