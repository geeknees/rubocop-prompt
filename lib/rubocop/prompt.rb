# frozen_string_literal: true

require_relative "prompt/version"
require_relative "prompt/plugin"
require_relative "cop/prompt/invalid_format"
require_relative "cop/prompt/critical_first_last"
require_relative "cop/prompt/system_injection"
require_relative "cop/prompt/max_tokens"
require_relative "cop/prompt/missing_stop"

module RuboCop
  module Prompt
    class Error < StandardError; end
  end
end
