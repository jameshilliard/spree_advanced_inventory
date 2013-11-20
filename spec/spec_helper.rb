# Configure Rails Environment
ENV["RAILS_ENV"] ||= "test"

require File.expand_path("../dummy/config/environment.rb",  __FILE__)

require 'rspec/rails'
require 'ffaker'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[File.join(File.dirname(__FILE__), "support/**/*.rb")].each {|f| require f }

# Requires factories defined in spree_core
require 'spree/core/testing_support/factories'
require 'spree/core/testing_support/capybara_ext'
require 'spree/core/testing_support/controller_requests'
require 'spree/core/testing_support/authorization_helpers'
require 'spree/core/testing_support/preferences'
require 'spree/core/testing_support/flash'
require 'spree/core/url_helpers'
require 'paperclip/matchers'

RSpec.configure do |config|
  config.color = true
  config.mock_with :rspec
  config.use_transactional_fixtures = false
  config.include Devise::TestHelpers, :type => :controller
  config.include FactoryGirl::Syntax::Methods
  config.include Spree::Core::UrlHelpers
  config.include Spree::Core::TestingSupport::ControllerRequests
  config.include Spree::Core::TestingSupport::Preferences
  config.include Spree::Core::TestingSupport::Flash

end

