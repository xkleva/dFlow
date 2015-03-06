require 'rails_helper'

RSpec.describe Source, :type => :model do
  before :each do
    #config_init
    #WebMock.allow_net_connect!
    @libris = Source.find_by_name('libris')
  end
  after :each do
    #WebMock.allow_net_connect!
  end
  describe "fetch source data" do
    context "with an existing libris ID" do
      it "should return a hash with values" do
        data = @libris.fetch_source_data(1234)
        expect(data[:title]).to start_with("Water")
        expect(data[:metadata][:type_of_record]).to eq("am")
      end
    end
    context "with a non-existing libris ID" do
      it "should return an empty object" do
        data = @libris.fetch_source_data(1)
        expect(data.empty?).to be true
      end
    end
  end

  describe "find by name" do
    context "when source is available" do
      it "should find a class" do
        my_source = Source.find_by_name('libris')
        expect(my_source).not_to be nil
        expect(my_source).to be Libris
      end
    end
    context "when using a nonsense source name" do
      it "should return error" do
        my_source = Source.find_by_name('tjottabengtson')
        expect(my_source).to be nil
      end
    end
  end

end
