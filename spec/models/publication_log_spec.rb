require 'rails_helper'

RSpec.describe PublicationLog, :type => :model do
  describe "self.types" do
    context "with types configured" do
      it "should return a list of types" do
        APP_CONFIG['publication_types'] = ['WIKIPEDIA', 'TWO', 'THREE']

        types = PublicationLog.types

        expect(types).to eq ['WIKIPEDIA', 'TWO', 'THREE']
      end
    end
    context "with types unconfigured" do
      it "should return an empty array" do
        APP_CONFIG['publication_types'] = nil

        types = PublicationLog.types

        expect(types).to eq []
      end
    end
  end
end
