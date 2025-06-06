# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Prompt
      # Checks for missing stop tokens or max_tokens in OpenAI::Client.chat calls.
      #
      # This cop identifies OpenAI::Client.chat method calls and ensures they include
      # either stop: or max_tokens: parameters to prevent runaway generation and
      # ensure predictable behavior.
      #
      # @example
      #   # bad
      #   OpenAI::Client.new.chat(
      #     parameters: {
      #       model: "gpt-4",
      #       messages: [{ role: "user", content: "Hello" }]
      #     }
      #   )
      #
      #   # bad
      #   client.chat(
      #     parameters: {
      #       model: "gpt-4",
      #       messages: messages
      #     }
      #   )
      #
      #   # good
      #   OpenAI::Client.new.chat(
      #     parameters: {
      #       model: "gpt-4",
      #       messages: [{ role: "user", content: "Hello" }],
      #       max_tokens: 100
      #     }
      #   )
      #
      #   # good
      #   client.chat(
      #     parameters: {
      #       model: "gpt-4",
      #       messages: messages,
      #       stop: ["END", "\n"]
      #     }
      #   )
      #
      #   # good
      #   client.chat(
      #     parameters: {
      #       model: "gpt-4",
      #       messages: messages,
      #       max_tokens: 1000,
      #       stop: ["END"]
      #     }
      #   )
      class MissingStop < RuboCop::Cop::Base
        MSG = "OpenAI::Client.chat call should include 'stop:' or 'max_tokens:' parameter to prevent runaway generation"

        def on_send(node)
          return unless openai_chat_call?(node)

          parameters_hash = extract_parameters_hash(node)
          return unless parameters_hash

          return if has_stop_or_max_tokens?(parameters_hash)

          add_offense(node)
        end

        private

        def openai_chat_call?(node)
          return false unless node.method_name == :chat

          # Check if this is called on OpenAI::Client instance
          # This could be either:
          # 1. OpenAI::Client.new.chat
          # 2. client.chat (where client is an OpenAI::Client instance)
          receiver = node.receiver
          return false unless receiver

          # Case 1: OpenAI::Client.new.chat
          if receiver.type == :send && receiver.method_name == :new && openai_client_const?(receiver.receiver)
            return true
          end

          # Case 2: Variable/method call that likely contains an OpenAI::Client
          # Look for patterns like:
          # - client.chat (where client variable is used)
          # - method_returning_client.chat
          # We'll check the surrounding context for OpenAI::Client instantiation
          return true if openai_client_context?(node)

          false
        end

        def openai_client_const?(node)
          return false unless node&.type == :const

          # Check for OpenAI::Client constant
          # The AST structure is: s(:const, s(:const, nil, :OpenAI), :Client)
          if node.children[0]&.type == :const
            outer_const = node.children[0]
            # Check if it's s(:const, nil, :OpenAI) and current is :Client
            outer_const.children[0].nil? && outer_const.children[1] == :OpenAI && node.children[1] == :Client
          else
            false
          end
        end

        def openai_client_context?(node)
          # Check if we're in a context that suggests OpenAI::Client usage
          # Look for OpenAI::Client.new assignment in the same method or class
          return true if find_openai_client_assignment(node)

          # Check if the receiver variable name suggests it's an OpenAI client
          receiver = node.receiver
          return true if receiver&.type == :lvar && openai_client_variable_name?(receiver.children[0])

          false
        end

        def find_openai_client_assignment(node)
          # Traverse up to find the containing method or class
          current = node
          while current&.parent
            current = current.parent
            break if %i[def defs class module].include?(current.type)
          end

          return false unless current

          # Search for OpenAI::Client.new assignments in the same scope
          found_assignment = false
          current.each_descendant(:lvasgn, :ivasgn, :cvasgn, :gvasgn) do |assignment_node|
            next unless assignment_node.children[1]

            # Check if the assignment is to OpenAI::Client.new
            value_node = assignment_node.children[1]
            next unless value_node.type == :send && value_node.method_name == :new &&
                        openai_client_const?(value_node.receiver)

            found_assignment = true
            break
          end

          found_assignment
        end

        def openai_client_variable_name?(var_name)
          # Common variable names that suggest OpenAI client usage
          client_patterns = %w[client openai_client ai_client llm_client chat_client api_client]
          var_name_str = var_name.to_s.downcase

          client_patterns.any? { |pattern| var_name_str.include?(pattern) }
        end

        def extract_parameters_hash(node)
          # Look for parameters: { ... } in the method arguments
          node.arguments.each do |arg|
            next unless arg.type == :hash

            arg.children.each do |pair|
              next unless pair.type == :pair

              key_node = pair.children[0]
              value_node = pair.children[1]

              next unless key_node.type == :sym && key_node.children[0] == :parameters
              return value_node if value_node.type == :hash

              # If parameters is not a hash (e.g., a variable), we can't analyze it
              return nil
            end
          end

          nil
        end

        def has_stop_or_max_tokens?(hash_node)
          return false unless hash_node.type == :hash

          hash_node.children.any? do |pair|
            next false unless pair.type == :pair

            key_node = pair.children[0]
            next false unless key_node.type == :sym

            key_name = key_node.children[0]
            %i[stop max_tokens].include?(key_name)
          end
        end
      end
    end
  end
end
