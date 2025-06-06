# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Prompt
      # Checks that system: blocks start with a Markdown heading.
      #
      # This cop identifies code in classes, modules, or methods with "prompt" in their names
      # and ensures that any system: blocks begin with a Markdown heading (# text).
      #
      # @example
      #   # bad
      #   system: <<~PROMPT
      #     You are an AI assistant.
      #   PROMPT
      #
      #   # good
      #   system: <<~PROMPT
      #     # System Instructions
      #     You are an AI assistant.
      #   PROMPT
      class InvalidFormat < RuboCop::Cop::Base
        MSG = "system: block should start with a Markdown heading (# text)"

        def on_pair(node)
          return unless system_pair?(node)
          return unless in_prompt_context?(node)

          value_node = node.children[1]
          content = extract_content(value_node)

          return if content.nil? || content.strip.empty?
          return if starts_with_markdown_heading?(content)

          add_offense(node)
        end

        private

        def system_pair?(node)
          return false unless node.type == :pair

          key_node = node.children[0]
          key_node.type == :sym && key_node.children[0] == :system
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

        def extract_content(node)
          case node.type
          when :str
            node.children[0]
          when :dstr
            # Handle heredoc content
            node.children.filter_map do |child|
              child.children[0] if child.type == :str
            end.join
          end
        end

        def starts_with_markdown_heading?(content)
          # Remove leading whitespace and check if it starts with #
          trimmed = content.gsub("\\n", "\n").strip
          # Check if the first non-empty line starts with # followed by space and text
          first_line = trimmed.lines.first&.strip
          first_line&.match?(/^#\s+.+/)
        end
      end
    end
  end
end
