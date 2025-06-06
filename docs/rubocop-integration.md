# RuboCop Integration

## Extension Architecture
This gem extends RuboCop functionality by providing prompt-based features for enhanced code analysis.

## Key Components
- **Prompt Module**: Core functionality for prompt-based interactions
- **RuboCop Integration**: Seamless integration with RuboCop's analyzer
- **Configuration**: Customizable settings for prompt behavior

## Implementation Notes
- Follow RuboCop's plugin architecture
- Extend existing RuboCop classes where appropriate
- Maintain compatibility with different RuboCop versions
- Provide clear error messages and user feedback

## Configuration
- Support YAML-based configuration
- Allow customization of prompt behavior
- Integrate with existing `.rubocop.yml` files

## Testing RuboCop Extensions
- Test against multiple RuboCop versions
- Include integration tests with real Ruby code
- Mock RuboCop internals where necessary
- Test configuration loading and validation
