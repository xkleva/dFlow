require 'rails_helper'

RSpec.configure do |c|
	c.include ModelHelper
end

RSpec.describe Job, :type => :model do
  before :each do
		
	end
	it "should update metadata correctly" do
		job = Job.find(1)
		new_data = {type: "testtype", page_count: 100}
		job.update_metadata_key("job",new_data)
		expect(job).to be_a Job
		expect(JSON.parse(job.metadata)["job"]["type"] == "testtype").to be true

		new_data = {type: "testtype2", page_count: 89}
		job.update_metadata_key("job",new_data)
		expect(job).to be_a Job
		expect(JSON.parse(job.metadata)["job"]["type"] == "testtype2").to be true
		expect(JSON.parse(job.metadata)["job"]["page_count"] == 89).to be true
	end
end