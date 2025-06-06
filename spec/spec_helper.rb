# frozen_string_literal: true

require "rubocop"
require "rubocop/rspec/support"
require "rubocop/prompt"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # Include RuboCop's testing support
  config.include RuboCop::RSpec::ExpectOffense
end
