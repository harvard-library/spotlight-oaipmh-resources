$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "spotlight/oaipmh/resources/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "spotlight-oaipmh-resources"
  s.version     = Spotlight::Oaipmh::Resources::VERSION
  s.authors     = ["Dee Dee Crema"]
  s.email       = ["valdeva_crema@harvard.edu"]
  s.summary     = "Ingest of OaiPmh harvests into Spotlight"
  s.license     = "MIT"

  s.files = Dir["{app,config,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_dependency 'oai'
  s.add_dependency 'mods'
  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_bot_rails'
  s.add_development_dependency "riiif"
  s.add_development_dependency 'libxml-ruby'
  s.add_development_dependency "engine_cart", '0.10.0'
  s.add_development_dependency 'database_cleaner', '~> 1.3'
  s.add_development_dependency 'blacklight-gallery'
  s.add_development_dependency 'sitemap_generator'
  
end
