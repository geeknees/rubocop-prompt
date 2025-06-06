# RuboCop::Prompt

A RuboCop plugin for analyzing and improving AI prompt quality in Ruby code. This gem provides cops to detect common anti-patterns in AI prompt engineering, helping developers write better prompts for LLM interactions.

## Features

- **Prompt/InvalidFormat**: Ensures `system:` blocks start with Markdown headings for better structure and readability
- **Prompt/CriticalFirstLast**: Ensures labeled sections (### text) appear at the beginning or end, not in the middle
- **Prompt/SystemInjection**: Detects dynamic interpolation in SYSTEM heredocs to prevent prompt injection vulnerabilities
- **Prompt/MaxTokens**: Checks that documentation text in prompt-related code doesn't exceed the maximum token limit using tiktoken_ruby

## Installation

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

## Usage

Add the following to your `.rubocop.yml`:

```yaml
plugins:
  - rubocop-prompt

Prompt/InvalidFormat:
  Enabled: true

Prompt/CriticalFirstLast:
  Enabled: true

Prompt/SystemInjection:
  Enabled: true

Prompt/MaxTokens:
  Enabled: true
  MaxTokens: 4000  # Optional: customize token limit (default: 4000)
```

## Cops

### Prompt/SystemInjection

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

### Prompt/MaxTokens

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

**Scope**: This cop only analyzes Ruby files where class names, module names, or method names contain "prompt" (case-insensitive). Regular strings in non-prompt-related code are ignored.

### Prompt/InvalidFormat

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

**Scope**: This cop only analyzes Ruby files where class names, module names, or method names contain "prompt" (case-insensitive). This helps avoid false positives in unrelated code.

**Detection**: The cop identifies `system:` key-value pairs and checks if the content starts with a Markdown heading (# followed by text).

### Prompt/CriticalFirstLast

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

**Scope**: This cop only analyzes Ruby files where class names, module names, or method names contain "prompt" (case-insensitive). It applies to both `system:` blocks and regular string/heredoc content.

**Detection**: The cop identifies lines starting with `###` and ensures they appear in the first third or last third of the content, not in the middle third.

## Examples

Here are some examples of code that will trigger the cops:

```ruby
# Triggers Prompt/InvalidFormat offense - no heading
class UserPromptGenerator
  def system_message
    { system: "Help the user with their request" }
  end
end

# Triggers Prompt/InvalidFormat offense - doesn't start with heading
module PromptTemplates
  CHAT_SYSTEM = { system: <<~TEXT }
    You are a helpful assistant.

    # Guidelines
    Follow these rules...
  TEXT
end

# Triggers Prompt/MaxTokens offense - exceeds token limit (example with low limit)
class PromptHelper
  def generate_long_prompt
    # Assuming MaxTokens is set to 50 for this example
    <<~PROMPT
      This is a very long prompt that contains many words and detailed instructions
      that will definitely exceed the configured token limit and trigger an offense.
    PROMPT
  end
end
```

And examples that won't trigger the cops:

```ruby
# No offense - starts with heading (Prompt/InvalidFormat)
class PromptBuilder
  def build
    {
      system: <<~MARKDOWN
        # AI Assistant Instructions

        You are a helpful AI assistant.
      MARKDOWN
    }
  end
end

# No offense - within token limit (Prompt/MaxTokens)
class PromptHelper
  def generate_prompt
    <<~PROMPT
      # Instructions
      You are a helpful assistant.
    PROMPT
  end
end

# No offense - not in prompt-related context (all cops)
class DatabaseService
  def config
    { system: "production" }  # This won't be flagged by any prompt cops
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rubocop-prompt. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/rubocop-prompt/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the RuboCop::Prompt project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/rubocop-prompt/blob/main/CODE_OF_CONDUCT.md).
