# -*- coding: utf-8 -*-
require 'rails_helper'

RSpec.describe QueueManager, :type => :model do
   describe "self.run"    do
       before :each do
           @queue_manager_config = APP_CONFIG['queue_manager'].merge(SYSTEM_DATA['queue_manager'])
           @pid_file = Pathname.new(@queue_manager_config['pid_file_location'])
           FileUtils.rm(@pid_file, :force => true)
       end
       context "no existing pid file" do
           it "should return warning msg" do 
               expect(QueueManager.logger).to receive(:warn).with("No PID file exists, aborting QueueManager")
               QueueManager.run
           end
       end
       context "existing erroneus pid file" do
           it "should return fatal msg" do 
               current_pid = '12345'
               file = File.open(@pid_file, "w:utf-8") do |file|
                   file.write(current_pid)
               end
               expect(QueueManager.logger).to receive(:fatal).with("PID #{current_pid} - from file #{@pid_file} doesn't match my process #{Process.pid}, aborting QueueManager")
               QueueManager.run
           end
       end
       context "no job process" do
           it "should return debug msg" do 
               Job.delete_all
               current_pid = Process.pid
               file = File.open(@pid_file, "w:utf-8") do |file|
                   file.write(current_pid)
               end
               expect(QueueManager.logger).to receive(:debug).with("No job to process at this time")
               QueueManager.run(loop: false)
           end
       end
      context "existing job process" do
          it "should return info msg" do 
            job = create(:job)
            SYSTEM_DATA['processes'] << {"code" => "TEST_PROCESS", "state" => "PROCESS"}
            flow_step = create(:flow_step, process: "TEST_PROCESS", step: 999, job: job, entered_at: DateTime.now)
            job.set_current_flow_step(flow_step)
            current_pid = Process.pid
            file = File.open(@pid_file, "w:utf-8") do |file|
              file.write(current_pid)
            end
            expect(QueueManager.logger).to_not receive(:debug).with("No job to process at this time")
            QueueManager.run(loop: false)
          end
      end
   end

   describe "self.get_job_for_automatic_process" do
     context "for no existing jobs" do
       it "should return nil" do
         Job.delete_all

         result = QueueManager.get_job_waiting_for_automatic_process

         expect(result).to be nil
       end
     end
     context "for an existing job with current flow step not being an automatic process" do
       it "should return nil" do
         job = create(:job)

         result = QueueManager.get_job_waiting_for_automatic_process

         expect(result).to be nil
       end
     end
     context "for an existing job with current flow step being an automatic process" do
       it "should return the job object" do
         job = create(:job)
         SYSTEM_DATA['processes'] << {"code" => "TEST_PROCESS", "state" => "PROCESS"}
         flow_step = create(:flow_step, process: "TEST_PROCESS", step: 999, job: job, entered_at: DateTime.now)
         job.set_current_flow_step(flow_step)

         result = QueueManager.get_job_waiting_for_automatic_process

         expect(result).to be_a Job
         expect(result.id).to eq job.id
       end
     end
   end
end


