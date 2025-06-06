# frozen_string_literal: true

require_relative "prompt/version"
require_relative "prompt/plugin"

module RuboCop
  module Prompt
    class Error < StandardError; end
  end
end

# Load all cops
require_relative "cop/prompt/invalid_format"
