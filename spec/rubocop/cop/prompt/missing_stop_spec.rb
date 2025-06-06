# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Prompt::MissingStop, :config do
  subject(:cop) { described_class.new(config) }

  context "when OpenAI::Client.chat call is missing stop and max_tokens" do
    it "registers an offense for OpenAI::Client.new.chat without stop or max_tokens" do
      expect_offense(<<~RUBY)
        OpenAI::Client.new.chat(
        ^^^^^^^^^^^^^^^^^^^^^^^^ OpenAI::Client.chat call should include 'stop:' or 'max_tokens:' parameter to prevent runaway generation
          parameters: {
            model: "gpt-4",
            messages: [{ role: "user", content: "Hello" }]
          }
        )
      RUBY
    end

    it "registers an offense for client.chat without stop or max_tokens" do
      expect_offense(<<~RUBY)
        client = OpenAI::Client.new
        OpenAI::Client.new.chat(
        ^^^^^^^^^^^^^^^^^^^^^^^^ OpenAI::Client.chat call should include 'stop:' or 'max_tokens:' parameter to prevent runaway generation
          parameters: {
            model: "gpt-4",
            messages: messages
          }
        )
      RUBY
    end

    it "registers an offense for variable client without stop or max_tokens" do
      expect_offense(<<~RUBY)
        def chat_completion(user_msg, context, prompt_type)
          client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
          client.chat(parameters: {
          ^^^^^^^^^^^^^^^^^^^^^^^^^ OpenAI::Client.chat call should include 'stop:' or 'max_tokens:' parameter to prevent runaway generation
            model: ENV.fetch("OPENAI_CHAT_MODEL", "gpt-4o-mini"),
            messages: [
              { role: "system", content: "You are an AI assistant" },
              { role: "user", content: "\#{user_msg}\\n\\n### 参考資料\\n\#{context}" }
            ]
          })
        end
      RUBY
    end

    it "registers an offense for openai_client variable without stop or max_tokens" do
      expect_offense(<<~RUBY)
        def process_request
          openai_client = OpenAI::Client.new
          openai_client.chat(parameters: {
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ OpenAI::Client.chat call should include 'stop:' or 'max_tokens:' parameter to prevent runaway generation
            model: "gpt-4",
            messages: messages
          })
        end
      RUBY
    end

    it "registers an offense when only other parameters are present" do
      expect_offense(<<~RUBY)
        OpenAI::Client.new.chat(
        ^^^^^^^^^^^^^^^^^^^^^^^^ OpenAI::Client.chat call should include 'stop:' or 'max_tokens:' parameter to prevent runaway generation
          parameters: {
            model: "gpt-4",
            messages: messages,
            temperature: 0.7,
            top_p: 1.0
          }
        )
      RUBY
    end
  end

  context "when OpenAI::Client.chat call includes stop or max_tokens" do
    it "does not register an offense when max_tokens is present" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.chat(
          parameters: {
            model: "gpt-4",
            messages: [{ role: "user", content: "Hello" }],
            max_tokens: 100
          }
        )
      RUBY
    end

    it "does not register an offense when stop is present" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.chat(
          parameters: {
            model: "gpt-4",
            messages: messages,
            stop: ["END", "\\n"]
          }
        )
      RUBY
    end

    it "does not register an offense when both stop and max_tokens are present" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.chat(
          parameters: {
            model: "gpt-4",
            messages: messages,
            max_tokens: 1000,
            stop: ["END"]
          }
        )
      RUBY
    end

    it "does not register an offense when stop is an array" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.chat(
          parameters: {
            model: "gpt-4",
            messages: messages,
            stop: ["\\n", "END", "STOP"]
          }
        )
      RUBY
    end

    it "does not register an offense when stop is a string" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.chat(
          parameters: {
            model: "gpt-4",
            messages: messages,
            stop: "END"
          }
        )
      RUBY
    end

    it "does not register an offense for variable client with max_tokens" do
      expect_no_offenses(<<~RUBY)
        def chat_completion(user_msg, context, prompt_type)
          client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])
          client.chat(parameters: {
            model: ENV.fetch("OPENAI_CHAT_MODEL", "gpt-4o-mini"),
            messages: [
              { role: "system", content: "You are an AI assistant" },
              { role: "user", content: "\#{user_msg}\\n\\n### 参考資料\\n\#{context}" }
            ],
            max_tokens: 1000
          })
        end
      RUBY
    end

    it "does not register an offense for variable client with stop tokens" do
      expect_no_offenses(<<~RUBY)
        def process_request
          openai_client = OpenAI::Client.new
          openai_client.chat(parameters: {
            model: "gpt-4",
            messages: messages,
            stop: ["END", "\\n"]
          })
        end
      RUBY
    end
  end

  context "when method call is not OpenAI chat" do
    it "does not register an offense for other chat methods" do
      expect_no_offenses(<<~RUBY)
        other_client.chat(
          parameters: {
            model: "some-model",
            messages: messages
          }
        )
      RUBY
    end

    it "does not register an offense for non-chat methods" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.completions(
          parameters: {
            model: "gpt-4",
            prompt: "Hello"
          }
        )
      RUBY
    end

    it "does not register an offense for methods without parameters" do
      expect_no_offenses(<<~RUBY)
        client.chat
      RUBY
    end
  end

  context "when parameters structure is different" do
    it "does not register an offense when parameters is not a hash" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.chat(
          parameters: params_variable
        )
      RUBY
    end

    it "does not register an offense when no parameters key is found" do
      expect_no_offenses(<<~RUBY)
        OpenAI::Client.new.chat(
          model: "gpt-4",
          messages: messages
        )
      RUBY
    end
  end
end
