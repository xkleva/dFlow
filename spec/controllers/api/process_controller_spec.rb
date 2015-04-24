require 'rails_helper'

RSpec.describe Api::ProcessController, :type => :controller do

  describe "request_job" do
    context "a job with status waiting_for_package_metadata_import exists" do
      it "should return a job" do
        create(:job, status: 'waiting_for_package_metadata_import');
        get :request_job, code: 'PACKAGE_METADATA_IMPORT'
        expect(response.status).to eq 200
        expect(json['job']).to_not be nil
        expect(json['job']['status']).to eq 'package_metadata_import'
      end
    end
  end
end
