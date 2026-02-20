ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # SQLite + threaded parallel tests are unstable on Windows.
    # Default to 1 worker and allow opt-in scaling via PARALLEL_WORKERS.
    parallelize(
      workers: ENV.fetch("PARALLEL_WORKERS", "1").to_i,
      with: :threads,
      threshold: 100
    )

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
