# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.describe WaitForFiles, :type => :model do

  describe "self.run" do
    context "for a folder with less files than given count" do
      it "should return false" do
        flow_step = create(:flow_step, process: "WAIT_FOR_FILES", params: {count: 30, folder_path: "TEST:/12345/", filetype: "tif"}.to_json)
        job = flow_step.job
        job.set_current_flow_step(flow_step)
        result = WaitForFiles.run(job: flow_step.job, logger: QueueManager.logger)

        expect(result).to be false
      end
    end

    context "for a folder with same amount of files as given count" do
      it "should return true" do
        flow_step = create(:flow_step, process: "WAIT_FOR_FILES", params: {count: 8, folder_path: "TEST:/12345/", filetype: "tif"}.to_json)
        job = flow_step.job
        job.set_current_flow_step(flow_step)
        result = WaitForFiles.run(job: flow_step.job, logger: QueueManager.logger)

        expect(result).to be true
      end
    end

    context "for a folder with jobid given as parameter and page count as job parameter" do
      it "should return true" do
        flow_step = create(:flow_step, process: "WAIT_FOR_FILES", params: {count: '%{page_count}', folder_path: "TEST:/%{job_id}/", filetype: "tif"}.to_json)
        job = create(:job, id: 12345, package_metadata: {image_count: 8}.to_json)
        flow_step.update_attribute('job_id', job.id)
        job.set_current_flow_step(flow_step)
        result = WaitForFiles.run(job: job, logger: QueueManager.logger)

        expect(result).to be true
      end
    end
  end
end
