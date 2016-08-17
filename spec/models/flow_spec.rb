require 'rails_helper'

RSpec.describe Flow, :type => :model do
  # Validations

  describe "name" do
    it {should validate_uniqueness_of(:name)}
  end

  describe "folder_paths, steps, parameters" do
    context "with an invalid json block" do
      it "should return an error message when updating" do
        flow = create(:flow)
        flow.folder_paths = 'asd'
        flow.steps = 'asd'
        flow.parameters = 'asd'

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:folder_paths]).to include("JSON ParseError: 757: unexpected token at 'asd'")
        expect(flow.errors.messages[:steps]).to include("JSON ParseError: 757: unexpected token at 'asd'")
        expect(flow.errors.messages[:parameters]).to include("JSON ParseError: 757: unexpected token at 'asd'")
      end
    end
    context "with valid json block" do
      it "should not return an error message when updating" do
        flow = create(:flow)
        flow.folder_paths = '{}'
        flow.steps = '{}'
        flow.parameters = '{}'
        flow.validate_json

        expect(flow.errors).to be_empty
      end
    end
  end

end
