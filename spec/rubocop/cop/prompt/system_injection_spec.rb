# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Prompt::SystemInjection, :config do
  subject(:cop) { described_class.new(config) }

  context "when SYSTEM heredoc contains interpolation in prompt context" do
    it "registers an offense when using interpolation in SYSTEM heredoc in prompt class" do
      expect_offense(<<~RUBY)
        class PromptHandler
          def generate_system_prompt(user_msg)
            <<~SYSTEM
            ^^^^^^^^^ Avoid dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities
              You are an AI assistant. User said: \#{user_msg}
            SYSTEM
          end
        end
      RUBY
    end

    it "registers an offense when using interpolation in SYSTEM heredoc in prompt method" do
      expect_offense(<<~RUBY)
        class Handler
          def create_prompt(input)
            <<~SYSTEM
            ^^^^^^^^^ Avoid dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities
              Process this: \#{input}
            SYSTEM
          end
        end
      RUBY
    end

    it "registers an offense when using interpolation in SYSTEM heredoc in prompt module" do
      expect_offense(<<~RUBY)
        module PromptHelpers
          def system_message(data)
            <<~SYSTEM
            ^^^^^^^^^ Avoid dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities
              Data: \#{data}
            SYSTEM
          end
        end
      RUBY
    end
  end

  context "when SYSTEM heredoc does not contain interpolation" do
    it "does not register an offense for SYSTEM heredoc without interpolation in prompt context" do
      expect_no_offenses(<<~RUBY)
        class PromptHandler
          def generate_system_prompt
            <<~SYSTEM
              You are an AI assistant.
              Follow these instructions carefully.
            SYSTEM
          end
        end
      RUBY
    end
  end

  context "when interpolation is not in SYSTEM heredoc" do
    it "does not register an offense for interpolation in non-SYSTEM heredoc in prompt context" do
      expect_no_offenses(<<~RUBY)
        class PromptHandler
          def generate_user_message(input)
            <<~USER
              Please process: \#{input}
            USER
          end
        end
      RUBY
    end
  end

  context "when not in prompt context" do
    it "does not register an offense for interpolation in SYSTEM heredoc outside prompt context" do
      expect_no_offenses(<<~RUBY)
        class DatabaseHandler
          def system_info(data)
            <<~SYSTEM
              System info: \#{data}
            SYSTEM
          end
        end
      RUBY
    end
  end

  context "with complex interpolation patterns" do
    it "registers an offense for complex interpolation in prompt class" do
      expect_offense(<<~RUBY)
        class ChatPromptGenerator
          def build_system(user_data, context)
            prompt = <<~SYSTEM
                     ^^^^^^^^^ Avoid dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities
              You are an assistant.
              User context: \#{user_data[:context]}
              Additional info: \#{context}
            SYSTEM
          end
        end
      RUBY
    end
  end

  context "with static strings" do
    it "does not register an offense for static strings in prompt context" do
      expect_no_offenses(<<~RUBY)
        class PromptBuilder
          def create_system
            "You are an AI assistant."
          end
        end
      RUBY
    end
  end

  context "with method names containing prompt" do
    it "registers an offense in method with prompt in name" do
      expect_offense(<<~RUBY)
        class AIHandler
          def generate_system_prompt_for_chat(msg)
            <<~SYSTEM
            ^^^^^^^^^ Avoid dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities
              Chat context: \#{msg}
            SYSTEM
          end
        end
      RUBY
    end
  end

  context "with module names containing Prompt" do
    it "registers an offense in module with Prompt in name" do
      expect_offense(<<~RUBY)
        module ChatPromptUtils
          def self.system_message(input)
            <<~SYSTEM
            ^^^^^^^^^ Avoid dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities
              Input: \#{input}
            SYSTEM
          end
        end
      RUBY
    end
  end
end
