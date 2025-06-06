# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Prompt::MaxTokens, :config do
  subject(:cop) { described_class.new(config) }

  let(:config) do
    RuboCop::Config.new(
      {
        "Prompt/MaxTokens" => {
          "MaxTokens" => max_tokens
        }
      },
      "/.rubocop.yml"
    )
  end

  let(:max_tokens) { 10 } # Use a low limit for testing

  context "when string is in a prompt-related class" do
    it "registers an offense when string exceeds token limit" do
      expect_offense(<<~RUBY)
        class PromptHelper
          def configure
            "This is a very long string that definitely contains more than ten tokens when counted"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Documentation text exceeds maximum token limit (15 > 10 tokens)
          end
        end
      RUBY
    end

    it "does not register an offense when string is within token limit" do
      expect_no_offenses(<<~RUBY)
        class PromptHelper
          def configure
            "Short text"
          end
        end
      RUBY
    end

    it "registers an offense when heredoc exceeds token limit" do
      expect_offense(<<~RUBY)
        class PromptHelper
          def configure
            <<~PROMPT
            ^^^^^^^^^ Documentation text exceeds maximum token limit (20 > 10 tokens)
              This is a very long heredoc that contains many words and will definitely exceed our token limit
            PROMPT
          end
        end
      RUBY
    end

    it "does not register an offense when heredoc is within token limit" do
      expect_no_offenses(<<~RUBY)
        class PromptHelper
          def configure
            <<~PROMPT
              Short
            PROMPT
          end
        end
      RUBY
    end
  end

  context "when string is in a module with prompt in name" do
    it "registers an offense when string exceeds token limit" do
      expect_offense(<<~RUBY)
        module PromptGeneration
          def build
            "This is another very long string that will exceed our ten token limit for testing purposes"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Documentation text exceeds maximum token limit (16 > 10 tokens)
          end
        end
      RUBY
    end
  end

  context "when string is in a method with prompt in name" do
    it "registers an offense when string exceeds token limit" do
      expect_offense(<<~RUBY)
        class Helper
          def create_prompt
            "This is a long string that exceeds the token limit we have set for testing"
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Documentation text exceeds maximum token limit (15 > 10 tokens)
          end
        end
      RUBY
    end

    it "does not register an offense when string is within token limit" do
      expect_no_offenses(<<~RUBY)
        class Helper
          def create_prompt
            "Short"
          end
        end
      RUBY
    end
  end

  context "when string is not in a prompt-related context" do
    it "does not register an offense even when string is long" do
      expect_no_offenses(<<~RUBY)
        class RegularClass
          def configure
            "This is a very long string that would normally exceed the token limit but should not trigger an offense"
          end
        end
      RUBY
    end
  end

  context "when string is empty" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class PromptHelper
          def configure
            ""
          end
        end
      RUBY
    end
  end

  context "with custom MaxTokens configuration" do
    let(:max_tokens) { 50 }

    it "uses the configured token limit" do
      expect_no_offenses(<<~RUBY)
        class PromptHelper
          def configure
            "This string has more than 10 tokens but less than 50 tokens so it should pass"
          end
        end
      RUBY
    end
  end

  context "with default MaxTokens configuration" do
    let(:config) { RuboCop::Config.new({}, "/.rubocop.yml") }

    it "uses the default token limit of 4000" do
      expect_no_offenses(<<~RUBY)
        class PromptHelper
          def configure
            "This string is definitely under 4000 tokens"
          end
        end
      RUBY
    end
  end
end
