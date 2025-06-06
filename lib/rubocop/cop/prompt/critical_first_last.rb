# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Prompt
      # Checks that labeled sections (### Text) appear at the beginning or end of files,
      # not in the middle.
      #
      # This cop identifies code in classes, modules, or methods with "prompt" in their names
      # and ensures that any labeled sections (lines starting with ###) are positioned
      # at the beginning or end of the content, not in the middle sections.
      #
      # @example
      #   # bad
      #   system: <<~PROMPT
      #     # System Instructions
      #     You are an AI assistant.
      #     ### Important Note
      #     Please follow these guidelines.
      #     More instructions here.
      #   PROMPT
      #
      #   # good
      #   system: <<~PROMPT
      #     ### Important Note
      #     Please follow these guidelines.
      #     # System Instructions
      #     You are an AI assistant.
      #   PROMPT
      class CriticalFirstLast < RuboCop::Cop::Base
        MSG = "Labeled sections (### text) should appear at the beginning or end, not in the middle"

        def on_pair(node)
          return unless system_pair?(node)
          return unless in_prompt_context?(node)

          value_node = node.children[1]
          content = extract_content(value_node)

          return if content.nil? || content.strip.empty?

          check_labeled_sections(node, content)
        end

        def on_str(node)
          return unless in_prompt_context?(node)
          return if node.each_ancestor(:pair).any? { |ancestor| system_pair?(ancestor) }

          content = node.children[0]
          return if content.nil? || content.strip.empty?

          check_labeled_sections(node, content)
        end

        def on_dstr(node)
          return unless in_prompt_context?(node)
          return if node.each_ancestor(:pair).any? { |ancestor| system_pair?(ancestor) }

          content = extract_content(node)
          return if content.nil? || content.strip.empty?

          check_labeled_sections(node, content)
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

        def check_labeled_sections(node, content)
          # Normalize line endings and split into lines
          normalized_content = content.gsub(/\\n/, "\n")
          lines = normalized_content.split("\n").map(&:strip).reject(&:empty?)
          
          # Find all lines that start with ###
          labeled_sections = []
          lines.each_with_index do |line, index|
            if line.match?(/^###\s+.+/)
              labeled_sections << index
            end
          end

          return if labeled_sections.empty?

          # Check if any labeled sections are in the middle
          total_lines = lines.size
          return if total_lines <= 6 # Need at least 7 lines to have meaningful middle

          # Define first third and last third boundaries
          first_third = [(total_lines / 3.0).ceil, 2].max
          last_third = total_lines - [(total_lines / 3.0).ceil, 2].max

          middle_sections = labeled_sections.select do |line_index|
            line_index >= first_third && line_index < last_third
          end

          return if middle_sections.empty?

          add_offense(node)
        end
      end
    end
  end
end
