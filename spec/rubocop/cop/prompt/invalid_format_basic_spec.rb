# frozen_string_literal: true

require "spec_helper"

RSpec.describe RuboCop::Cop::Prompt::InvalidFormat do
  subject(:cop) { described_class.new }

  it "exists and can be instantiated" do
    expect(cop).to be_a(RuboCop::Cop::Prompt::InvalidFormat)
  end

  it "has the correct cop name" do
    expect(cop.cop_name).to eq("Prompt/InvalidFormat")
  end
end
