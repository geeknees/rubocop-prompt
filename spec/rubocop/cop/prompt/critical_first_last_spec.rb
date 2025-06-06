# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Prompt::CriticalFirstLast, :config do
  subject(:cop) { described_class.new(config) }

  context "when in prompt context" do
    it "registers an offense for ### in middle of heredoc" do
      expect_offense(<<~RUBY)
        class PromptHandler
          def process
            content = <<~TEXT
                      ^^^^^^^ Labeled sections (### text) should appear at the beginning or end, not in the middle
              First line
              Second line
              Third line
              Fourth line
              ### Middle Section
              Sixth line
              Seventh line
              Eighth line
              Ninth line
            TEXT
          end
        end
      RUBY
    end

    it "registers an offense for system: block with ### in middle" do
      expect_offense(<<~RUBY)
        class PromptHandler
          def process
            {
              system: <<~PROMPT
              ^^^^^^^^^^^^^^^^^ Labeled sections (### text) should appear at the beginning or end, not in the middle
                # System Instructions
                You are an AI assistant.
                Please help users.
                ### Important Note
                This is critical.
                More instructions.
                Final instructions.
              PROMPT
            }
          end
        end
      RUBY
    end

    it "does not register an offense for ### at beginning" do
      expect_no_offenses(<<~RUBY)
        class PromptHandler
          def process
            content = <<~TEXT
              ### Beginning Section
              Second line
              Third line
              Fourth line
              Fifth line
            TEXT
          end
        end
      RUBY
    end

    it "does not register an offense for ### at end" do
      expect_no_offenses(<<~RUBY)
        class PromptHandler
          def process
            content = <<~TEXT
              First line
              Second line
              Third line
              Fourth line
              ### End Section
            TEXT
          end
        end
      RUBY
    end

    it "does not register an offense for system: block with ### at beginning" do
      expect_no_offenses(<<~RUBY)
        class PromptHandler
          def process
            {
              system: <<~PROMPT
                ### Important Note
                This is critical.
                # System Instructions
                You are an AI assistant.
                Please help users.
              PROMPT
            }
          end
        end
      RUBY
    end
  end

  context "when not in prompt context" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class Handler
          def process
            content = <<~TEXT
              First line
              Second line
              ### Middle Section
              Fourth line
              Fifth line
            TEXT
          end
        end
      RUBY
    end
  end
end
