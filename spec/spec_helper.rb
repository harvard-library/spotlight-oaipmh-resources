ENV["RAILS_ENV"] ||= 'test'

require 'devise'
require 'engine_cart'

if ENV["COVERAGE"] or ENV["CI"]
  require 'simplecov'
  require 'coveralls' if ENV["CI"]

  SimpleCov.root(File.expand_path('../..', __FILE__))
  SimpleCov.formatter = Coveralls::SimpleCov::Formatter if ENV["CI"]
  SimpleCov.start('rails') do
    add_filter '/.internal_test_app'
    add_filter '/lib/generators'
    add_filter '/spec'
  end
  SimpleCov.command_name 'spec'
end

EngineCart.load_application!

require 'rspec/rails'
require 'capybara'
require 'factory_bot_rails'
#FactoryBot.definition_file_paths ||= []
#FactoryBot.definition_file_paths << "#{Gem.loaded_specs['blacklight-spotlight'].full_gem_path}/spec/factories"
#FactoryBot.find_definitions

require 'database_cleaner'
require 'spotlight'

Dir["./spec/support/**/*.rb"].sort.each {|f| require f}


RSpec.configure do |config|
  config.use_transactional_fixtures = false

  config.before :each do
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :truncation
    end
    DatabaseCleaner.start
  end

  config.after do
    DatabaseCleaner.clean
  end

  if defined? Devise::Test::ControllerHelpers
    config.include Devise::Test::ControllerHelpers, type: :controller
    config.include Devise::Test::ControllerHelpers, type: :view
  else
    config.include Devise::TestHelpers, type: :controller
    config.include Devise::TestHelpers, type: :view
  end
  config.include Warden::Test::Helpers, type: :feature
  config.after(:each, type: :feature) { Warden.test_reset! }
  config.include Capybara::DSL
end
