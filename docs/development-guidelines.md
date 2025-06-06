# Development Guidelines

## Coding Standards
- Follow Ruby community best practices
- Adhere to RuboCop style guidelines
- Use frozen string literals
- Write comprehensive tests using RSpec
- Maintain type signatures using RBS

## File Organization
- Keep main logic in `lib/rubocop/prompt.rb`
- Place version information in `lib/rubocop/prompt/version.rb`
- Write tests in `spec/` directory mirroring `lib/` structure
- Maintain RBS type definitions in `sig/` directory

## Testing
- Use RSpec for all tests
- Maintain good test coverage
- Test both positive and negative cases
- Include integration tests for RuboCop functionality

## Dependencies
- Ruby >= 3.1.0
- RuboCop (as peer dependency)
- Development dependencies managed via Gemfile

## Release Process
1. Update version in `lib/rubocop/prompt/version.rb`
2. Update CHANGELOG (if exists)
3. Run full test suite
4. Use `bundle exec rake release` for gem publication
