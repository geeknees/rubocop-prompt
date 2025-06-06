# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Prompt::TemperatureRange, :config do
  subject(:cop) { described_class.new(config) }

  context "when in prompt context" do
    context "with high temperature for precision tasks" do
      it "registers an offense for temperature > 0.7 with accuracy keywords" do
        expect_offense(<<~RUBY)
          class PromptGenerator
            def generate_analysis_prompt
              OpenAI::Client.new.chat(
              ^^^^^^^^^^^^^^^^^^^^^^^^ High temperature (0.9 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
                parameters: {
                  temperature: 0.9,
                  messages: [
                    { role: "system", content: "Analyze this data accurately" }
                  ]
                }
              )
            end
          end
        RUBY
      end

      it "registers an offense for temperature > 0.7 with calculation keywords" do
        expect_offense(<<~RUBY)
          def prompt_calculator
            client.chat(
            ^^^^^^^^^^^^ High temperature (0.8 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
              temperature: 0.8,
              messages: [
                { role: "user", content: "Calculate the exact result" }
              ]
            )
          end
        RUBY
      end

      it "registers an offense for temperature > 0.7 with factual keywords" do
        expect_offense(<<~RUBY)
          class AIPromptService
            def fact_check_prompt
              client.complete(
              ^^^^^^^^^^^^^^^^ High temperature (1.0 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
                parameters: {
                  temperature: 1.0,
                  messages: [
                    { role: "system", content: "Verify the factual information" }
                  ]
                }
              )
            end
          end
        RUBY
      end

      it "registers an offense for temperature > 0.7 with code-related keywords" do
        expect_offense(<<~RUBY)
          module PromptUtils
            def debug_prompt
              api.chat(
              ^^^^^^^^^ High temperature (0.9 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
                temperature: 0.9,
                messages: [
                  { role: "user", content: "Debug this code and fix the error" }
                ]
              )
            end
          end
        RUBY
      end

      it "registers an offense with multiple precision keywords" do
        expect_offense(<<~RUBY)
          class PromptAnalyzer
            def analysis_prompt
              client.chat(
              ^^^^^^^^^^^^ High temperature (0.8 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
                parameters: {
                  temperature: 0.8,
                  messages: [
                    { role: "system", content: "Analyze and classify this data accurately" }
                  ]
                }
              )
            end
          end
        RUBY
      end
    end

    context "when temperature is acceptable" do
      it "does not register an offense for temperature <= 0.7 with precision tasks" do
        expect_no_offenses(<<~RUBY)
          class PromptGenerator
            def generate_analysis_prompt
              OpenAI::Client.new.chat(
                parameters: {
                  temperature: 0.3,
                  messages: [
                    { role: "system", content: "Analyze this data accurately" }
                  ]
                }
              )
            end
          end
        RUBY
      end

      it "does not register an offense for high temperature with creative tasks" do
        expect_no_offenses(<<~RUBY)
          def prompt_creator
            client.chat(
              temperature: 0.9,
              messages: [
                { role: "user", content: "Write a creative story about adventures" }
              ]
            )
          end
        RUBY
      end

      it "does not register an offense for temperature exactly 0.7" do
        expect_no_offenses(<<~RUBY)
          class AIPromptService
            def precise_prompt
              client.complete(
                parameters: {
                  temperature: 0.7,
                  messages: [
                    { role: "system", content: "Calculate the exact result" }
                  ]
                }
              )
            end
          end
        RUBY
      end

      it "does not register an offense for high temperature without precision keywords" do
        expect_no_offenses(<<~RUBY)
          module PromptUtils
            def creative_prompt
              api.chat(
                temperature: 0.9,
                messages: [
                  { role: "user", content: "Generate a fun and interesting response" }
                ]
              )
            end
          end
        RUBY
      end
    end

    context "with different message structures" do
      it "registers an offense with heredoc messages" do
        expect_offense(<<~RUBY)
          class PromptService
            def analysis_prompt
              client.chat(
              ^^^^^^^^^^^^ High temperature (0.8 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
                temperature: 0.8,
                messages: [
                  {
                    role: "system",
                    content: <<~CONTENT
                      You are an AI that needs to analyze data precisely.
                      Please provide accurate results.
                    CONTENT
                  }
                ]
              )
            end
          end
        RUBY
      end

      it "registers an offense with multiple messages containing precision keywords" do
        expect_offense(<<~RUBY)
          def prompt_with_multiple_messages
            client.chat(
            ^^^^^^^^^^^^ High temperature (0.9 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
              parameters: {
                temperature: 0.9,
                messages: [
                  { role: "system", content: "You are a helpful assistant" },
                  { role: "user", content: "Please calculate the exact total" }
                ]
              }
            )
          end
        RUBY
      end
    end

    context "with integer temperature values" do
      it "registers an offense for integer temperature > 0.7" do
        expect_offense(<<~RUBY)
          class PromptGenerator
            def analysis_prompt
              client.chat(
              ^^^^^^^^^^^^ High temperature (1.0 > 0.7) should not be used for precision tasks. Consider using temperature <= 0.7 for tasks requiring accuracy.
                temperature: 1,
                messages: [
                  { role: "system", content: "Analyze this data accurately" }
                ]
              )
            end
          end
        RUBY
      end
    end
  end

  context "when not in prompt context" do
    it "does not register an offense even with high temperature and precision keywords" do
      expect_no_offenses(<<~RUBY)
        class DataAnalyzer
          def process_data
            client.chat(
              temperature: 0.9,
              messages: [
                { role: "system", content: "Analyze this data accurately" }
              ]
            )
          end
        end
      RUBY
    end
  end

  context "when temperature is not specified" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class PromptGenerator
          def analysis_prompt
            client.chat(
              messages: [
                { role: "system", content: "Analyze this data accurately" }
              ]
            )
          end
        end
      RUBY
    end
  end

  context "when messages are not specified" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        def prompt_method
          client.chat(
            temperature: 0.9
          )
        end
      RUBY
    end
  end

  context "when method is not a chat method" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class PromptGenerator
          def some_other_method
            other_api.process(
              temperature: 0.9,
              messages: [
                { role: "system", content: "Analyze this data accurately" }
              ]
            )
          end
        end
      RUBY
    end
  end
end
