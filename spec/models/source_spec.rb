require 'rails_helper'

RSpec.describe Source, :type => :model do
	before :each do
		@libris = Source.where(classname: "Libris").first
	end
	describe "fetch_source_id" do
		context "with an existing libris ID" do
			it "should return a hash with values" do
				data = @libris.fetch_source_data(1234)
				expect(data[:title]).to start_with("Water")
				expect(data[:metadata][:type_of_record]).to eq("am")
			end
		end
		context "with a non existing libris ID" do
			it "should return an empty object" do
				data = @libris.fetch_source_data(1)
				expect(data.empty?).to be true
			end
		end
	end
end
