# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Prompt
      # Checks for dynamic variable interpolation in SYSTEM heredocs.
      #
      # This cop identifies code in classes, modules, or methods with "prompt" in their names
      # and ensures that SYSTEM heredocs do not contain dynamic variable interpolations like #{user_msg}.
      # Dynamic interpolation in system prompts can lead to prompt injection vulnerabilities.
      #
      # @example
      #   # bad
      #   <<~SYSTEM
      #     You are an AI assistant. The user said: #{user_msg}
      #   SYSTEM
      #
      #   # bad
      #   <<~SYSTEM
      #     Process this request: #{params[:input]}
      #   SYSTEM
      #
      #   # good
      #   <<~SYSTEM
      #     You are an AI assistant.
      #   SYSTEM
      #
      #   # good (using separate user message)
      #   system_prompt = <<~SYSTEM
      #     You are an AI assistant.
      #   SYSTEM
      #   user_message = user_msg
      class SystemInjection < RuboCop::Cop::Base
        MSG = "Avoid dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities"

        def on_dstr(node)
          return unless in_prompt_context?(node)
          return unless system_heredoc?(node)
          return unless has_interpolation?(node)

          add_offense(node)
        end

        private

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

        def system_heredoc?(node)
          return false unless node.type == :dstr

          # Check if this heredoc has the SYSTEM delimiter
          # Get the source of the heredoc opening
          source = node.source_range.source_buffer.source
          line_start = node.source_range.begin_pos

          # Find the start of the line containing the heredoc
          line_begin = source.rindex("\n", line_start - 1) || 0
          line_begin += 1 if line_begin > 0

          # Get the line content
          line_end = source.index("\n", line_start) || source.length
          line_content = source[line_begin...line_end]

          # Check if line contains SYSTEM heredoc marker
          line_content.include?("<<~SYSTEM") || line_content.include?("<<SYSTEM")
        end

        def has_interpolation?(node)
          # Check if any child nodes are interpolations (begin nodes)
          node.children.any? { |child| child.type == :begin }
        end
      end
    end
  end
end
