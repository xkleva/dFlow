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

  describe "steps validations" do
    before :all do
      @steps_mocks = YAML.load_file("#{Rails.root}/spec/support/flow_mocks/steps_mock.yml")
    end
    context "flow is missing a start step" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['MISSING_START'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("No start step exist (add the param 'start': true to first step)")
      end
    end
    context "flow is missing an end step" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['MISSING_END'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("No end step exist (add the param 'end': true to last step)")
      end
    end
    context "flow has more than one start step" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['MORE_THAN_ONE_START'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("Only one start step is allowed (remove param 'start': true from one of steps: [10, 20])")
      end
    end
    context "flow has more than one end step" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['MORE_THAN_ONE_END'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("Only one end step is allowed (remove param 'end': true from one of steps: [20, 30])")
      end
    end
    context "flow has duplicated step numbers" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['DUPLICATE_STEPS'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("Duplicated step nrs exist: [10]")
      end
    end
    context "flow has duplicated goto numbers" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['DUPLICATE_GOTO'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("Duplicated goto_true nrs exist: [30]")
      end
    end
    context "flow has goto numbers that do not exist" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['GOTO_NOT_EXIST'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("Given goto_true step does not exist: [30]")
      end
    end
    context "flow has steps with no goto numbers pointing at them" do
      it "should return an error message" do
        flow = create(:flow) 
        flow.steps = @steps_mocks['STEP_NOT_POINTED_AT'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:steps]).to include("All steps not pointed to by goto")
      end
    end
  end

  describe "parameter validations" do
    before :all do
      @parameters_mocks = YAML.load_file("#{Rails.root}/spec/support/flow_mocks/parameters_mock.yml")
    end
    context "there are multiple parameters with the same name" do
      it "should return an error message" do
        flow = create(:flow)
        flow.parameters = @parameters_mocks['DUPLICATE_NAME'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:parameters]).to include("Duplicated parameter names exist: [\"param1\"]")
      end
    end
    context "there is a parameter with an invalid name" do
      it "should return an error message" do
        flow = create(:flow)
        flow.parameters = @parameters_mocks['INVALID_NAME'].to_json

        expect(flow.valid?).to be false
        expect(flow.errors.messages[:parameters]).to include("Invalid parameter name: 123!@# only [a-z] [0-9] [- _] are allowed")
      end
    end
  end

  describe "flow_step_order_array" do
    context "for a valid flow" do
      it "should return an array of flow steps in order" do
        flow = build(:flow)

        expect(flow.flow_step_order_array).to eq [10,20]
      end
    end
  end

  describe "flow_step_is_before?" do
    context "for a flow step which is before other step" do
      it "should return true" do
        flow = build(:flow)

        result =flow.flow_step_is_before?(current_step: 10, other_step: 20)

        expect(result).to be true
      end
    end

    context "for a flow step which is after other step" do
      it "should return false" do
        flow = build(:flow)

        result =flow.flow_step_is_before?(current_step: 20, other_step: 10)

        expect(result).to be false
      end
    end

    context "for a flow step which is not part of the flow" do
      it "should raise an exception" do
        flow = build(:flow)

        expect{flow.flow_step_is_before?(current_step: 123, other_step: 10)}.to raise_error
      end
    end
    context "for a flow step against a step which is not part of the flow" do
      it "should raise an exception" do
        flow = build(:flow)

        expect{flow.flow_step_is_before?(current_step: 10, other_step: 123)}.to raise_error
      end
    end
  end



end
