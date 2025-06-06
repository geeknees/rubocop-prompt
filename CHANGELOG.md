# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-06-06

### Changed
-  Enhance OpenAI Client Detection and Specification Handling

## [0.1.0] - 2025-06-06

### Added
- Initial release of RuboCop::Prompt
- Six core cops for AI prompt quality analysis:
  - `Prompt/InvalidFormat` - Enforces Markdown formatting conventions
  - `Prompt/CriticalFirstLast` - Ensures critical sections at beginning/end
  - `Prompt/SystemInjection` - Prevents prompt injection vulnerabilities
  - `Prompt/MaxTokens` - Limits token count using tiktoken_ruby
  - `Prompt/MissingStop` - Requires stop/max_tokens parameters
  - `Prompt/TemperatureRange` - Validates temperature for task type
- Smart scope detection (only analyzes prompt-related code)
- Integration with tiktoken_ruby for accurate token counting
- Comprehensive documentation and examples

[0.1.0]: https://github.com/geeknees/rubocop-prompt/releases/tag/v0.1.0
