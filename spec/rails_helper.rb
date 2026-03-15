require "spec_helper"

ENV["RAILS_ENV"] = "test"   # ← ここが重要（||= じゃなくて =）
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# spec/support配下を読み込む（create_user等）
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  config.use_transactional_fixtures = true
  config.filter_rails_from_backtrace!

  config.include TestHelpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FactoryBot::Syntax::Methods

  config.before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  config.before(:each, type: :request) do
    host! "www.example.com"
  end
end
