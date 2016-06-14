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
      #context "existing job process" do
      #    it "should return info msg" do 
      #        #SYSTEM_DATA['processes'] << {"code" => "TEST_PROCESS", "state" => "PROCESS"}
      #        flow_step = create(:flow_step, entered_at: DateTime.now) 
      #        job = flow_step.job
      #        current_pid = Process.pid
      #        file = File.open(@pid_file, "w:utf-8") do |file|
      #            file.write(current_pid)
      #        end
      #        expect(QueueManager.logger).to receive(:info).with("Starting #{job.flow_step.process} for job #{job.id}")
      #        QueueManager.run
      #    end
      #end
   end
end


