# RuboCop::Prompt

A RuboCop plugin for analyzing and improving AI prompt quality in Ruby code. This gem provides cops to detect common anti-patterns in AI prompt engineering, helping developers write better prompts for LLM interactions.

## Why Use RuboCop::Prompt?

AI prompt engineering is critical for reliable LLM applications, but common mistakes can lead to:
- **Security vulnerabilities** from prompt injection
- **Unexpected costs** from runaway token generation
- **Poor AI responses** from badly structured prompts
- **Inconsistent results** from inappropriate temperature settings

This plugin helps catch these issues early in your development cycle.

## Available Cops

| Cop | Purpose | Key Benefit |
|-----|---------|-------------|
| **Prompt/InvalidFormat** | Ensures prompts start with Markdown headings | Better structure and readability |
| **Prompt/CriticalFirstLast** | Keeps important sections at beginning/end | Prevents buried critical instructions |
| **Prompt/SystemInjection** | Detects dynamic interpolation vulnerabilities | Prevents prompt injection attacks |
| **Prompt/MaxTokens** | Limits token count using tiktoken_ruby | Controls costs and context limits |
| **Prompt/MissingStop** | Requires stop/max_tokens parameters | Prevents runaway generation |
| **Prompt/TemperatureRange** | Validates temperature for task type | Ensures appropriate creativity levels |

## Quick Start

### 1. Installation

Add this line to your application's Gemfile:

```ruby
gem 'rubocop-prompt'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install rubocop-prompt
```

### 2. Configuration

Add the following to your `.rubocop.yml`:

```yaml
plugins:
  - rubocop-prompt

# Enable all cops with recommended settings
Prompt/InvalidFormat:
  Enabled: true

Prompt/CriticalFirstLast:
  Enabled: true

Prompt/SystemInjection:
  Enabled: true

Prompt/MaxTokens:
  Enabled: true
  MaxTokens: 4000  # Customize for your model's context window

Prompt/MissingStop:
  Enabled: true

Prompt/TemperatureRange:
  Enabled: true
```

### 3. Run RuboCop

```bash
bundle exec rubocop
```

That's it! RuboCop will now analyze your prompt-related code and suggest improvements.

## Detailed Cop Documentation

### 🛡️ Prompt/SystemInjection

**Purpose**: Prevents prompt injection vulnerabilities by detecting dynamic variable interpolation in SYSTEM heredocs.

**Why it matters**: User input directly interpolated into system prompts can allow attackers to override your instructions.

<details>
<summary>Show examples</summary>

Detects dynamic variable interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities.

This cop identifies code in classes, modules, or methods with "prompt" in their names and ensures that SYSTEM heredocs do not contain dynamic variable interpolations like `#{user_msg}`.

**Bad:**
```ruby
class PromptHandler
  def generate_system_prompt(user_input)
    <<~SYSTEM
      You are an AI assistant. User said: #{user_input}
    SYSTEM
  end
end
```

**Good:**
```ruby
class PromptHandler
  def generate_system_prompt
    <<~SYSTEM
      You are an AI assistant.
    SYSTEM
  end

  # Handle user input separately
  def process_user_input(user_input)
    # Process and sanitize user input here
  end
end
```

</details>

---

### 📏 Prompt/MaxTokens

**Purpose**: Ensures prompt content stays within token limits using accurate tiktoken_ruby calculations.

**Why it matters**: Exceeding token limits can cause API errors or unexpected truncation of your carefully crafted prompts.

<details>
<summary>Show examples</summary>

Checks that documentation text in prompt-related code doesn't exceed the maximum token limit using tiktoken_ruby.

This cop identifies code in classes, modules, or methods with "prompt" in their names and calculates the token count for any string literals or heredoc content. By default, it warns when the content exceeds 4000 tokens, which is suitable for most LLM contexts.

**Key Features:**
- Uses `tiktoken_ruby` with `cl100k_base` encoding (GPT-3.5/GPT-4 compatible)
- Configurable token limit via `MaxTokens` setting
- Includes fallback token approximation if tiktoken_ruby fails
- Only analyzes prompt-related contexts to avoid false positives

**Bad:**
```ruby
class PromptGenerator
  def create_system_prompt
    # This example assumes a very long prompt that exceeds the token limit
    <<~PROMPT
      # System Instructions

      You are an AI assistant with extensive knowledge about many topics.
      [... thousands of lines of detailed instructions that exceed 4000 tokens ...]
      Please follow all these detailed guidelines carefully.
    PROMPT
  end
end
```

**Good:**
```ruby
class PromptGenerator
  def create_system_prompt
    <<~PROMPT
      # System Instructions

      You are a helpful AI assistant.

      ## Guidelines
      - Be concise and accurate
      - Ask for clarification when needed
      - Provide helpful responses
    PROMPT
  end

  # For complex prompts, consider breaking them into smaller, focused components
  def create_specialized_prompt(domain)
    base_prompt = create_system_prompt
    domain_specific = load_domain_instructions(domain)  # Keep each part manageable
    "#{base_prompt}\n\n#{domain_specific}"
  end
end
```

**Configuration:**
```yaml
Prompt/MaxTokens:
  MaxTokens: 4000  # Default: 4000 tokens
  # MaxTokens: 8000  # For models with larger context windows
  # MaxTokens: 2000  # For more conservative token usage
```

</details>

---

### ⏹️ Prompt/MissingStop

**Purpose**: Ensures OpenAI API calls include proper termination parameters to prevent runaway generation.

**Why it matters**: Without stop conditions, AI responses can continue indefinitely, consuming excessive tokens and costs.

<details>
<summary>Show examples</summary>

Ensures that OpenAI::Client.chat calls include stop: or max_tokens: parameter to prevent runaway generation.

This cop identifies OpenAI::Client.chat method calls and ensures they include either stop: or max_tokens: parameters. These parameters are essential for controlling generation length and preventing unexpectedly long responses that could consume excessive tokens or processing time.

**Key Features:**
- Detects explicit OpenAI::Client.new.chat calls
- Checks for presence of stop: or max_tokens: parameters
- Helps prevent runaway generation and unexpected token consumption
- Only analyzes explicit OpenAI::Client calls to avoid false positives

**Bad:**
```ruby
class ChatService
  def generate_response
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: "Hello" }]
      }
    )
  end
end
```

**Good:**
```ruby
class ChatService
  def generate_response_with_limit
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: "Hello" }],
        max_tokens: 100
      }
    )
  end

  def generate_response_with_stop
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: "Hello" }],
        stop: ["END", "\n"]
      }
    )
  end

  def generate_response_with_both
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: "Hello" }],
        max_tokens: 1000,
        stop: ["END"]
      }
    )
  end
end
```

</details>

---

### 🌡️ Prompt/TemperatureRange

**Purpose**: Validates that temperature settings match the task requirements (low for precision, high for creativity).

**Why it matters**: Using high temperature (>0.7) for analytical tasks reduces accuracy, while low temperature limits creativity.

<details>
<summary>Show examples</summary>

Ensures that high temperature values (> 0.7) are not used for precision tasks requiring accuracy.

This cop identifies code in classes, modules, or methods with "prompt" in their names and ensures that when temperature > 0.7, it's not being used for tasks requiring precision, accuracy, or factual correctness. High temperature values increase randomness and creativity but can reduce accuracy for analytical tasks.

**Key Features:**
- Detects temperature values > 0.7 in chat/completion API calls
- Analyzes message content for precision-related keywords
- Helps ensure appropriate temperature settings for different task types
- Only triggers for prompt-related code contexts

**Bad:**
```ruby
class PromptGenerator
  def analysis_prompt
    OpenAI::Client.new.chat(
      parameters: {
        temperature: 0.9,  # Too high for precision task
        messages: [
          { role: "system", content: "Analyze this data accurately and provide precise results" }
        ]
      }
    )
  end

  def calculation_prompt
    client.chat(
      temperature: 0.8,  # Too high for calculation task
      messages: [
        { role: "user", content: "Calculate the exact total of these numbers" }
      ]
    )
  end
end
```

**Good:**
```ruby
class PromptGenerator
  # Low temperature for precision tasks
  def analysis_prompt
    OpenAI::Client.new.chat(
      parameters: {
        temperature: 0.3,  # Appropriate for precision
        messages: [
          { role: "system", content: "Analyze this data accurately and provide precise results" }
        ]
      }
    )
  end

  # High temperature is fine for creative tasks
  def creative_prompt
    client.chat(
      parameters: {
        temperature: 0.9,  # Fine for creative tasks
        messages: [
          { role: "user", content: "Write a creative story about space adventures" }
        ]
      }
    )
  end
end
```

**Detected precision keywords**: accurate, accuracy, precise, exact, analyze, calculate, fact, factual, classify, code, debug, technical, and others.

</details>

---

### 📋 Prompt/InvalidFormat

**Purpose**: Enforces Markdown formatting conventions in system prompts for better structure and readability.

**Why it matters**: Well-structured prompts with clear headings are easier to maintain and more effective.

<details>
<summary>Show examples</summary>

Ensures system prompts follow Markdown formatting conventions for better structure and readability.

**Anti-pattern**: System prompts without clear structure
```ruby
# Bad - will trigger offense
class PromptService
  def call
    { system: "You are an AI assistant." }
  end
end
```

**Good practice**: System prompts that start with Markdown headings
```ruby
# Good - properly structured
class PromptService
  def call
    {
      system: <<~PROMPT
        # System Instructions

        You are an AI assistant that helps users with their questions.

        ## Guidelines
        - Be helpful and accurate
        - Provide clear explanations
      PROMPT
    }
  end
end
```

</details>

---

### 🎯 Prompt/CriticalFirstLast

**Purpose**: Ensures important labeled sections (### text) appear at the beginning or end, not buried in the middle.

**Why it matters**: Critical instructions in the middle of prompts are often overlooked by AI models due to attention bias.

<details>
<summary>Show examples</summary>

Ensures that labeled sections (### text) appear at the beginning or end of content, not in the middle sections.

**Anti-pattern**: Critical labeled sections buried in the middle
```ruby
# Bad - will trigger offense
class PromptHandler
  def process
    {
      system: <<~PROMPT
        # System Instructions
        You are an AI assistant.
        Please help users with their questions.
        ### Important Note
        This is a critical section.
        More instructions follow.
        Final instructions here.
      PROMPT
    }
  end
end
```

**Good practice**: Critical sections at beginning or end
```ruby
# Good - critical section at beginning
class PromptHandler
  def process
    {
      system: <<~PROMPT
        ### Important Note
        This is a critical section.
        # System Instructions
        You are an AI assistant.
        Please help users with their questions.
      PROMPT
    }
  end
end

# Good - critical section at end
class PromptHandler
  def process
    {
      system: <<~PROMPT
        # System Instructions
        You are an AI assistant.
        Please help users with their questions.
        ### Important Note
        This is a critical section.
      PROMPT
    }
  end
end
```

</details>

---

## 🔍 Scope and Detection

All cops are designed to be **smart and focused**:
- Only analyze files with "prompt" in class/module/method names (case-insensitive)
- Avoid false positives in unrelated code
- Focus on actual AI/LLM integration patterns

## 💡 Quick Examples

### ❌ Code That Triggers Offenses

```ruby
# Triggers Prompt/InvalidFormat - no heading
class UserPromptGenerator
  def system_message
    { system: "Help the user with their request" }
  end
end

# Triggers Prompt/SystemInjection - dangerous interpolation
class ChatPromptService
  def generate_system_prompt(user_input)
    <<~SYSTEM
      You are an AI assistant. User said: #{user_input}
    SYSTEM
  end
end

# Triggers Prompt/MissingStop - no termination control
class ChatService
  def generate_response
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: "Hello" }]
      }
    )
  end
end
```

### ✅ Code That Follows Best Practices

```ruby
# ✅ Proper formatting with headings
class PromptBuilder
  def build
    {
      system: <<~MARKDOWN
        # AI Assistant Instructions

        You are a helpful AI assistant.

        ## Guidelines
        - Be helpful and accurate
        - Ask for clarification when needed
      MARKDOWN
    }
  end
end

# ✅ Safe prompt handling without injection risks
class SecurePromptService
  def generate_system_prompt
    <<~SYSTEM
      # AI Assistant Instructions

      You are a helpful AI assistant.
    SYSTEM
  end

  def process_user_input(user_input)
    # Handle user input separately with proper validation
  end
end

# ✅ Proper API usage with termination controls
class ControlledChatService
  def generate_response
    OpenAI::Client.new.chat(
      parameters: {
        model: "gpt-4",
        messages: [{ role: "user", content: "Hello" }],
        max_tokens: 100,
        stop: ["END"]
      }
    )
  end
end

# ✅ Won't be flagged - not prompt-related
class DatabaseService
  def config
    { system: "production" }  # Ignored by all prompt cops
  end
end
```

## 🚀 Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Local Development
```bash
# Setup
git clone https://github.com/[USERNAME]/rubocop-prompt
cd rubocop-prompt
bin/setup

# Run tests
rake spec

# Test with your own code
bin/console
```

### Release Process
To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Report bugs** - Found an issue? Open a GitHub issue
2. **Suggest new cops** - Have ideas for prompt anti-patterns to detect?
3. **Improve existing cops** - Better detection logic or clearer error messages
4. **Documentation** - Help make our docs even clearer

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rubocop-prompt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rubocop-prompt/blob/main/CODE_OF_CONDUCT.md).

## 📄 License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## 📋 Code of Conduct

Everyone interacting in the RuboCop::Prompt project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rubocop-prompt/blob/main/CODE_OF_CONDUCT.md).
