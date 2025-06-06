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
          return openai_client_const?(receiver.receiver) if receiver.type == :send && receiver.method_name == :new

          # Case 2: For now, we'll be conservative and only check explicit OpenAI::Client calls
          # to avoid false positives. In the future, this could be enhanced with more
          # sophisticated type analysis.
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
