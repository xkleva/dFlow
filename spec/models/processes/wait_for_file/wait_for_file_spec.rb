# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.describe WaitForFile, :type => :model do

  before :each do
    WebMock.disable_net_connect!
  end
  after :each do
    WebMock.allow_net_connect!
  end

  describe "self.run" do
    context "for a file that does not exist" do
      it "should return false" do
        flow_step = create(:flow_step, process: "WAIT_FOR_FILE", params: {file_path: "TEST:/12345/notexist.pdf"}.to_json)
        job = flow_step.job
        job.set_current_flow_step(flow_step)
        result = WaitForFile.run(job: flow_step.job, logger: QueueManager.logger)

        expect(result).to be false
      end
    end

    context "for a file that exists" do
      it "should return true" do
        flow_step = create(:flow_step, process: "WAIT_FOR_FILE", params: {file_path: "TEST:/12345/1.pdf"}.to_json)
        job = flow_step.job
        job.set_current_flow_step(flow_step)
        result = WaitForFile.run(job: flow_step.job, logger: QueueManager.logger)

        expect(result).to be true
      end
    end

  end
end
