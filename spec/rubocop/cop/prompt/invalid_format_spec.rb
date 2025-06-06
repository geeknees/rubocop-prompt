# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Prompt::InvalidFormat, :config do
  subject(:cop) { described_class.new(config) }

  context "when system: block is in a prompt-related class" do
    it "registers an offense when system block does not start with markdown heading" do
      expect_offense(<<~RUBY)
        class PromptHelper
          def configure
            {
              system: <<~PROMPT
              ^^^^^^^^^^^^^^^^^ system: block should start with a Markdown heading (# text)
                You are an AI assistant.
              PROMPT
            }
          end
        end
      RUBY
    end

    it "does not register an offense when system block starts with markdown heading" do
      expect_no_offenses(<<~RUBY)
        class PromptHelper
          def configure
            {
              system: <<~PROMPT
                # System Instructions
                You are an AI assistant.
              PROMPT
            }
          end
        end
      RUBY
    end

    it "registers an offense when system: uses a string literal" do
      expect_offense(<<~RUBY)
        module PromptGeneration
          def build_prompt
            {
              system: "You are an AI assistant."
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ system: block should start with a Markdown heading (# text)
            }
          end
        end
      RUBY
    end

    it "does not register an offense when system: string starts with heading" do
      expect_no_offenses(<<~RUBY)
        module PromptGeneration
          def build_prompt
            {
              system: "# System\\nYou are an AI assistant."
            }
          end
        end
      RUBY
    end
  end

  context "when system: block is in a method with prompt in the name" do
    it "registers an offense when system block does not start with markdown heading" do
      expect_offense(<<~RUBY)
        class Helper
          def create_prompt
            {
              system: "You are helpful."
              ^^^^^^^^^^^^^^^^^^^^^^^^^^ system: block should start with a Markdown heading (# text)
            }
          end
        end
      RUBY
    end

    it "does not register an offense when system block starts with markdown heading" do
      expect_no_offenses(<<~RUBY)
        class Helper
          def create_prompt
            {
              system: "# Instructions\\nYou are helpful."
            }
          end
        end
      RUBY
    end
  end

  context "when system: block is not in a prompt-related context" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class RegularClass
          def configure
            {
              system: "You are an AI assistant."
            }
          end
        end
      RUBY
    end
  end

  context "when system: block is empty" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class PromptHelper
          def configure
            {
              system: ""
            }
          end
        end
      RUBY
    end
  end
end
