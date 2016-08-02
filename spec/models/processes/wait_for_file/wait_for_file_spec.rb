# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.describe WaitForFile, :type => :model do

  describe "self.run" do
    context "for a file that does not exist" do
      it "should return false" do
        #job = create(:job)

        #result = WaitForFile.run(job: job, file_path: "TEST:/12345/notexist.pdf")

        #expect(result).to be false
      end
    end

    context "for a file that exists" do
      it "should return true" do
        #job = create(:job)

        #result = WaitForFile.run(job: job, file_path: "TEST:/12345/1.pdf")

        #expect(result).to be true
      end
    end

  end
end
