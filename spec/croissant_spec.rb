# frozen_string_literal: true

RSpec.describe Croissant do
  it 'should have a version number' do
    expect(Croissant::VERSION).not_to be_nil
  end
end
