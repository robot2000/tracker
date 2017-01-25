ENV['RAILS_ENV'] ||= 'test'
require 'simplecov'
require 'simplecov-json'
require 'simplecov-rcov'
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
  SimpleCov::Formatter::RcovFormatter
]
SimpleCov.start 'rails' do
  add_filter '/channels/'
  add_filter 'lib/clock.rb'
end

require 'spec_helper'
require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'capybara/webkit'
require 'capybara-screenshot/rspec'
require 'factory_girl'
require 'factory_girl_rails'
require 'webmock/rspec'
require 'site_prism'
require 'email_spec'
require 'ffaker'
require 'devise'

Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

Capybara::Webkit.configure(&:block_unknown_urls)
Capybara.save_path = 'tmp/capybara'

ActiveRecord::Migration.maintain_test_schema!

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_spec_type_from_file_location!
  config.order = :random
  config.include Warden::Test::Helpers
  config.include FactoryGirl::Syntax::Methods
  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include ActionDispatch::TestProcess,     type: :feature
  config.include AcceptenceHelper,                type: :feature
  config.include JsHelpers,                       type: :feature
  config.include EmailSpec::Helpers,              type: :mailer
  config.include EmailSpec::Matchers,             type: :mailer
  config.include OmniauthMacros
  config.include AbstractController::Translation
  config.include WaitForAjax,                     type: :feature

  Warden.test_mode!

  WebMock.disable_net_connect!(allow_localhost: true)

  Capybara.javascript_driver = :webkit
  Capybara.ignore_hidden_elements = true
  Capybara.default_max_wait_time = 5
  Capybara::Screenshot.prune_strategy = { keep: 10 }

  config.before :each do
    if Capybara.current_driver == :rack_test
      DatabaseCleaner.strategy = :transaction
    else
      DatabaseCleaner.strategy = :truncation
    end
    DatabaseCleaner.start
  end
  config.after :each do
    Warden.test_reset!
    DatabaseCleaner.clean
  end
end

SitePrism.configure do |config|
  config.use_implicit_waits = true
end
