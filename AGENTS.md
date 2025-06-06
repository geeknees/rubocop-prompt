# Agent Instructions for rubocop-prompt

## Project Context
This is a Ruby gem that extends RuboCop with prompt-based functionality. Please refer to the following documentation files for detailed information:

## Documentation References

### Project Information
- **Project Overview**: See `/docs/project-overview.md` for general project information, structure, and architecture
- **Development Guidelines**: See `/docs/development-guidelines.md` for coding standards, testing practices, and release process
- **RuboCop Integration**: See `/docs/rubocop-integration.md` for specific guidance on RuboCop extension development

## Key Development Practices

### When Working with This Project:
1. **Follow Ruby Conventions**: Use Ruby community best practices and RuboCop style guidelines
2. **Maintain Type Safety**: Update RBS files in `sig/` directory when adding new methods or classes
3. **Test-Driven Development**: Write comprehensive RSpec tests for all functionality
4. **RuboCop Integration**: Ensure compatibility with RuboCop's plugin architecture

### File Modifications:
- Main logic goes in `lib/rubocop/prompt.rb`
- Tests should be added to `spec/rubocop/prompt_spec.rb`
- Type definitions belong in `sig/rubocop/prompt.rbs`
- Follow the existing namespace structure: `Rubocop::Prompt`

### Testing:
- Run tests with `rake spec`
- Use `bin/console` for interactive development
- Ensure all new features have corresponding tests

### Dependencies:
- This is a Ruby gem project using Bundler
- RuboCop is a key dependency for extension functionality
- Maintain Ruby 3.1.0+ compatibility

For detailed information on any of these aspects, please consult the respective documentation files in the `/docs` directory.
