ENV['RAILS_ENV'] ||= 'test'

require File.expand_path('../../config/environment', __FILE__)
require 'rspec/rails'
require 'sunspot/rails/spec_helper'
require 'email_spec'
require 'devise'


RSpec.configure do |config|
  config.infer_spec_type_from_file_location!

  config.include FactoryGirl::Syntax::Methods
  config.include(EmailSpec::Helpers)
  config.include(EmailSpec::Matchers)
  config.include(Devise::TestHelpers, type: :controller)

  config.before(:suite) do
    DatabaseCleaner.clean_with :truncation
    DatabaseCleaner.strategy = :truncation
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  # solr
  config.before(:each) do
    ::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)
  end

  config.after(:each) do
    ::Sunspot.session = ::Sunspot.session.original_session
  end

end

# Delayed::Worker.delay_jobs = false

FactoryGirl.definition_file_paths = %w{spec/factories/}
FactoryGirl.find_definitions


