# Project Overview

## Project: rubocop-prompt

A Ruby gem that extends RuboCop with prompt-based functionality for enhanced code analysis and suggestions.

### Project Structure
```
lib/
  rubocop/
    prompt.rb        # Main module
    prompt/
      version.rb     # Version management
spec/
  rubocop/
    prompt_spec.rb   # Test specifications
sig/
  rubocop/
    prompt.rbs       # Type signatures (RBS)
```

### Development Workflow
- Use `bin/setup` to install dependencies
- Run `rake spec` to execute tests
- Use `bin/console` for interactive development
- Follow Ruby community best practices and RuboCop guidelines

### Architecture
- Follows standard Ruby gem structure
- Integrates with RuboCop as an extension
- Uses RBS for type definitions
- RSpec for testing
