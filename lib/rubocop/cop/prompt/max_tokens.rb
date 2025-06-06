# frozen_string_literal: true

require "rubocop"
require "tiktoken_ruby"

module RuboCop
  module Cop
    module Prompt
      # Checks that documentation text in prompt-related code doesn't exceed the maximum token limit.
      #
      # This cop identifies code in classes, modules, or methods with "prompt" in their names
      # and calculates the token count for any string literals or heredoc content using tiktoken_ruby.
      # By default, it warns when the content exceeds 4000 tokens.
      #
      # @example
      #   # bad (assuming very long content that exceeds token limit)
      #   def generate_prompt
      #     <<~PROMPT
      #       # This is a very long prompt that contains thousands of tokens...
      #       # [many lines of text]
      #     PROMPT
      #   end
      #
      #   # good
      #   def generate_prompt
      #     <<~PROMPT
      #       # A concise prompt that stays within token limits
      #       You are a helpful assistant.
      #     PROMPT
      #   end
      class MaxTokens < RuboCop::Cop::Base
        MSG = "Documentation text exceeds maximum token limit (%<actual>d > %<max>d tokens)"

        # Default maximum token count
        DEFAULT_MAX_TOKENS = 4000

        def on_str(node)
          return unless in_prompt_context?(node)

          content = node.children[0]
          return if content.nil? || content.strip.empty?

          check_token_count(node, content)
        end

        def on_dstr(node)
          return unless in_prompt_context?(node)

          # Handle heredoc content
          content = node.children.filter_map do |child|
            child.children[0] if child.type == :str
          end.join

          return if content.strip.empty?

          check_token_count(node, content)
        end

        private

        def check_token_count(node, content)
          token_count = calculate_tokens(content)
          max_tokens = cop_config["MaxTokens"] || DEFAULT_MAX_TOKENS

          return unless token_count > max_tokens

          add_offense(
            node,
            message: format(MSG, actual: token_count, max: max_tokens)
          )
        end

        def calculate_tokens(content)
          # Use tiktoken_ruby to calculate token count
          # Using cl100k_base encoding (used by GPT-3.5/GPT-4)
          encoder = Tiktoken.get_encoding("cl100k_base")
          encoder.encode(content).length
        rescue StandardError => e
          # If tiktoken_ruby fails for any reason, fall back to character count / 4
          # This is a rough approximation: 1 token ≈ 4 characters for English text
          warn "Failed to calculate tokens with tiktoken_ruby: #{e.message}. Using character approximation."
          content.length / 4
        end

        def in_prompt_context?(node)
          # Check if we're inside a class, module, or method that contains "prompt"
          node.each_ancestor(:class, :module, :def, :defs) do |ancestor|
            return true if has_prompt_in_name?(ancestor)
          end
          false
        end

        def has_prompt_in_name?(node)
          case node.type
          when :class, :module
            name_node = node.children[0]
            if name_node.type == :const
              name_node.children[1].to_s.downcase.include?("prompt")
            else
              false
            end
          when :def, :defs
            node.method_name.to_s.downcase.include?("prompt")
          else
            false
          end
        end
      end
    end
  end
end
