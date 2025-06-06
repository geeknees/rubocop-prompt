# frozen_string_literal: true

require_relative "lib/rubocop/prompt/version"

Gem::Specification.new do |spec|
  spec.name = "rubocop-prompt"
  spec.version = RuboCop::Prompt::VERSION
  spec.authors = ["Masumi Kawasaki"]
  spec.email = ["geeknees@gmail.com"]

  spec.summary = "A RuboCop extension for analyzing and improving AI prompt quality in Ruby code."
  spec.description = "This gem provides static analysis for common prompt engineering anti-patterns, helping developers write better prompts for LLM interactions."
  spec.homepage = "https://github.com/geeknees/rubocop-prompt"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["default_lint_roller_plugin"] = "RuboCop::Prompt::Plugin"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/geeknees/rubocop-prompt"
  spec.metadata["changelog_uri"] = "https://github.com/geeknees/rubocop-prompt/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "lint_roller"
  spec.add_dependency "rubocop", ">= 1.72.0", "< 2.0"
  spec.add_dependency "rubocop-ast", ">= 1.44.0", "< 2.0"
  spec.add_dependency "tiktoken_ruby", "~> 0.0.7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata["rubygems_mfa_required"] = "true"
end
