# frozen_string_literal: true

require "lint_roller"

module RuboCop
  module Prompt
    # A plugin that integrates RuboCop Prompt with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: "rubocop-prompt",
          version: VERSION,
          homepage: "https://github.com/your-username/rubocop-prompt",
          description: "A RuboCop extension for analyzing and improving AI prompt quality in Ruby code."
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join("../../../config/default.yml")
        )
      end
    end
  end
end
