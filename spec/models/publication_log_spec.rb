require 'rails_helper'

RSpec.describe PublicationLog, :type => :model do

  describe "publication_type" do
    it { should allow_value("OTHER").for(:publication_type) }
    it { should_not allow_value("NOTATYPE").for(:publication_type) }
  end

  describe "self.types" do
    context "with types configured" do
      it "should return a list of types" do
        SYSTEM_DATA['publication_types'] = ['WIKIPEDIA', 'TWO', 'THREE']

        types = PublicationLog.types

        expect(types).to eq ['WIKIPEDIA', 'TWO', 'THREE', 'OTHER']
      end
    end
    context "with types unconfigured" do
      it "should return an empty array" do
        SYSTEM_DATA['publication_types'] = nil

        types = PublicationLog.types

        expect(types).to eq ['OTHER']
      end
    end
  end
end
