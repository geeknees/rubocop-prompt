# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Prompt
      # Checks that temperature values are appropriate for the task type.
      #
      # This cop identifies code in classes, modules, or methods with "prompt" in their names
      # and ensures that when temperature > 0.7, it's not being used for precision tasks.
      # High temperature values (> 0.7) should be avoided for tasks requiring accuracy,
      # consistency, or factual correctness.
      #
      # @example
      #   # bad (high temperature for precision task)
      #   OpenAI::Client.new.chat(
      #     parameters: {
      #       temperature: 0.9,
      #       messages: [{ role: "system", content: "Analyze this data accurately" }]
      #     }
      #   )
      #
      #   # bad (high temperature with precision keywords)
      #   client.chat(
      #     temperature: 0.8,
      #     messages: [{ role: "user", content: "Calculate the exact result" }]
      #   )
      #
      #   # good (low temperature for precision)
      #   OpenAI::Client.new.chat(
      #     parameters: {
      #       temperature: 0.3,
      #       messages: [{ role: "system", content: "Analyze this data accurately" }]
      #     }
      #   )
      #
      #   # good (high temperature for creative task)
      #   OpenAI::Client.new.chat(
      #     parameters: {
      #       temperature: 0.9,
      #       messages: [{ role: "user", content: "Write a creative story" }]
      #     }
      #   )
      class TemperatureRange < RuboCop::Cop::Base
        MSG = "High temperature (%.1f > 0.7) should not be used for precision tasks. " \
              "Consider using temperature <= 0.7 for tasks requiring accuracy."

        # Temperature threshold above which we check for precision tasks
        TEMPERATURE_THRESHOLD = 0.7

        # Keywords that indicate precision/accuracy tasks
        PRECISION_KEYWORDS = [
          # Analysis and accuracy
          "accurate", "accuracy", "precise", "precision", "exact", "exactly",
          "analyze", "analysis", "calculate", "computation", "compute",
          "measure", "measurement", "count", "sum", "total",
          # Factual and data tasks
          "fact", "factual", "data", "information", "correct", "verify",
          "validate", "check", "review", "audit", "inspect",
          # Classification and categorization
          "classify", "classification", "categorize", "category",
          "sort", "organize", "structure", "parse", "extract",
          # Technical and code tasks
          "code", "programming", "syntax", "debug", "error", "fix",
          "technical", "documentation", "specification", "format"
        ].freeze

        def on_send(node)
          return unless in_prompt_context?(node)
          return unless chat_method?(node)

          temperature_value = extract_temperature(node)
          return unless temperature_value && temperature_value > TEMPERATURE_THRESHOLD

          messages = extract_messages(node)
          return unless messages && precision_task?(messages)

          add_offense(
            node,
            message: format(MSG, temperature_value)
          )
        end

        private

        def in_prompt_context?(node)
          # Check if we're inside a class, module, or method that contains "prompt"
          # Or if we're using an OpenAI client directly
          return true if openai_client_call?(node)

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

        def chat_method?(node)
          return false unless node.type == :send

          # Check for methods like chat, complete, or similar
          method_name = node.method_name.to_s
          return false unless %w[chat complete completion].include?(method_name)

          # Check if this is an OpenAI client method call
          return true if openai_client_call?(node)

          # Otherwise, just rely on method name for broader detection
          true
        end

        def openai_client_call?(node)
          return false unless node.type == :send
          
          # Check the receiver
          receiver = node.receiver
          return false unless receiver

          # Case 1: OpenAI::Client.new.chat
          return true if receiver.type == :send && receiver.method_name == :new && 
                         openai_client_const?(receiver.receiver)

          # Case 2: Variable/method call that likely contains an OpenAI::Client
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
            break if current.type == :def || current.type == :defs || current.type == :class || current.type == :module
          end

          return false unless current

          # Search for OpenAI::Client.new assignments in the same scope
          found_assignment = false
          current.each_descendant(:lvasgn, :ivasgn, :cvasgn, :gvasgn) do |assignment_node|
            next unless assignment_node.children[1]

            # Check if the assignment is to OpenAI::Client.new
            value_node = assignment_node.children[1]
            if value_node.type == :send && value_node.method_name == :new && 
               openai_client_const?(value_node.receiver)
              found_assignment = true
              break
            end
          end

          found_assignment
        end

        def openai_client_variable_name?(var_name)
          # Common variable names that suggest OpenAI client usage
          client_patterns = %w[client openai_client ai_client llm_client chat_client api_client]
          var_name_str = var_name.to_s.downcase
          
          client_patterns.any? { |pattern| var_name_str.include?(pattern) }
        end

        def extract_temperature(node)
          # Look for temperature in hash arguments
          node.arguments.each do |arg|
            next unless arg.type == :hash

            temperature = find_temperature_in_hash(arg)
            return temperature if temperature
          end

          nil
        end

        def find_temperature_in_hash(hash_node)
          hash_node.pairs.each do |pair|
            key = pair.key
            value = pair.value

            # Handle direct temperature key
            return extract_numeric_value(value) if key_matches?(key, "temperature")

            # Handle nested parameters hash
            return find_temperature_in_hash(value) if key_matches?(key, "parameters") && value.type == :hash
          end

          nil
        end

        def key_matches?(key_node, target_key)
          case key_node.type
          when :sym
            key_node.children[0].to_s == target_key
          when :str
            key_node.children[0] == target_key
          else
            false
          end
        end

        def extract_numeric_value(value_node)
          case value_node.type
          when :float
            value_node.children[0]
          when :int
            value_node.children[0].to_f
          end
        end

        def extract_messages(node)
          # Look for messages in hash arguments
          node.arguments.each do |arg|
            next unless arg.type == :hash

            messages = find_messages_in_hash(arg)
            return messages if messages
          end

          nil
        end

        def find_messages_in_hash(hash_node)
          hash_node.pairs.each do |pair|
            key = pair.key
            value = pair.value

            # Handle direct messages key
            return extract_messages_content(value) if key_matches?(key, "messages")

            # Handle nested parameters hash
            return find_messages_in_hash(value) if key_matches?(key, "parameters") && value.type == :hash
          end

          nil
        end

        def extract_messages_content(messages_node)
          return nil unless messages_node.type == :array

          content_strings = []
          messages_node.children.each do |message|
            next unless message.type == :hash

            message.pairs.each do |pair|
              if key_matches?(pair.key, "content")
                content = extract_string_content(pair.value)
                content_strings << content if content
              end
            end
          end

          content_strings.join(" ")
        end

        def extract_string_content(value_node)
          case value_node.type
          when :str
            value_node.children[0]
          when :dstr
            # Handle heredoc and interpolated strings
            value_node.children.filter_map do |child|
              child.children[0] if child.type == :str
            end.join
          end
        end

        def precision_task?(messages_content)
          return false if messages_content.nil? || messages_content.strip.empty?

          # Convert to lowercase for case-insensitive matching
          content_lower = messages_content.downcase

          # Check if any precision keywords are present
          PRECISION_KEYWORDS.any? { |keyword| content_lower.include?(keyword) }
        end
      end
    end
  end
end
