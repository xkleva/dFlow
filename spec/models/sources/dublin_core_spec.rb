require 'rails_helper'

RSpec.describe DublinCore, :type => :model do

  before :each do
    @dublin_core = Source.find_by_name('dc')
  end

  dc_data = {
    dc_title: 'The Title',
    dc_creator: 'The Creator',
    dc_subject: 'The Subject',
    dc_description: 'The Description',
    dc_publisher: 'The Publisher',
    dc_contributor: 'The Contributor',
    dc_date: 'The Date',
    dc_type: 'The Type',
    dc_format: 'The Format',
    dc_identifier: 'The Identifier',
    dc_source: 'The Source',
    dc_language: 'The Language',
    dc_relation: 'The Relation',
    dc_coverage: 'The Coverage',
    dc_rights: 'The Rights'
  }
  dc_data_complex = {
    dc_title: ['The Title #1', 'The Title #2', 'The Title #3'],
    dc_creator: ['The Creator #1', 'The Creator #2', 'The Creator #3'],
    dc_subject: ['The Subject #1', 'The Subject #2', 'The Subject #3'],
    dc_description: ['The Description #1'],
    dc_publisher: ['The Publisher #1'],
    dc_contributor: ['The Contributor #1'],
    dc_date: ['The Date #1', 'The Date #2', 'The Date #3'],
    dc_type: ['The Type #1', 'The Type #2', 'The Type #3'],
    dc_format: ['The Format #1', 'The Format #2', 'The Format #3'],
    dc_identifier: ['The Identifier #1', 'The Identifier #2', 'The Identifier #3'],
    dc_source: ['The Source #1', 'The Source #2', 'The Source #3'],
    dc_language: ['The Language #1', 'The Language #2', 'The Language #3'],
    dc_relation: ['The Relation #1', 'The Relation #2', 'The Relation #3'],
    dc_coverage: ['The Coverage #1', 'The Coverage #2', 'The Coverage #3'],
    dc_rights: ['The Rights #1', 'The Rights #2', 'The Rights #3']
  }

  describe "find the source" do
    context "when correctly configured" do
      it "should find a class for the source" do
        my_source = Source.find_by_name('dc')
        expect(my_source).not_to be nil
        expect(my_source).to be DublinCore
      end
    end
  end
  describe "fetch source data" do
    context "when dc data is provided" do
      it "should generate a catalog_id with the format dc:<uuid>" do
        data = @dublin_core.fetch_source_data(nil, dc_data)
        pp data
        expect(data[:catalog_id]).to start_with("dc:")
        # dc:xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
        #expect(data[:metadata][:type_of_record]).to eq("am")
      end
      it "should find the title in title" do
        data = @dublin_core.fetch_source_data(nil, dc_data)
        expect(data[:title]).to start_with("The Title")
      end
      it "should find the creator in author" do
        data = @dublin_core.fetch_source_data(nil, dc_data)
        expect(data[:author]).to start_with("The Creator")
      end
      it "should find the title in metadata" do
        data = @dublin_core.fetch_source_data(nil, dc_data)
        expect(data[:metadata][:dc_title]).to start_with("The Title")
      end
      it "should find the creator in metadata" do
        data = @dublin_core.fetch_source_data(nil, dc_data)
        expect(data[:metadata][:dc_creator]).to start_with("The Creator")
      end
      it "should find the subject in metadata" do
        data = @dublin_core.fetch_source_data(nil, dc_data)
        expect(data[:metadata][:dc_subject]).to start_with("The Subject")
      end
    end

    # context "when multilpe valued dc data is provided" do
    #   it "should find the title in title" do
    #     data = @dublin_core.fetch_source_data(nil, dc_data_complex)
    #     pp data
    #     expect(data[:title]).to start_with("The Title")
    #   end
    #   it "should find the creator in author" do
    #     data = @dublin_core.fetch_source_data(nil, dc_data_complex)
    #     expect(data[:author]).to start_with("The Creator")
    #   end
    #   it "should find the title in metadata" do
    #     data = @dublin_core.fetch_source_data(nil, dc_data_complex)
    #     expect(data[:metadata][:dc_title][0]).to start_with("The Title")
    #   end
    #   it "should find the creator in metadata" do
    #     data = @dublin_core.fetch_source_data(nil, dc_data_complex)
    #     expect(data[:metadata][:dc_creator]).to start_with("The Creator")
    #   end
    #   it "should find the subject in metadata" do
    #     data = @dublin_core.fetch_source_data(nil, dc_data_complex)
    #     expect(data[:metadata][:dc_subject]).to start_with("The Subject")
    #   end
    # end
  end

end
