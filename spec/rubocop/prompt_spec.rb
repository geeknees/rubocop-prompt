# frozen_string_literal: true

RSpec.describe RuboCop::Prompt do
  it "has a version number" do
    expect(RuboCop::Prompt::VERSION).not_to be nil
  end

  it "loads the plugin correctly" do
    expect(RuboCop::Prompt::Plugin).to be < LintRoller::Plugin
  end
end
