
class Api::WorkflowsController < ApplicationController
	before_filter :check_key
	
	#Method for changing status of a job based on job_id and new status
	def change_status
		job_id = params[:job_id].to_i
		status = params[:status]
		json = {"success" => "true"}

		job = Job.find(job_id) #Find job based on id
		status = Status.find_by_name(status) #Find new status
		event = Event.find_by_name("change_status") #Find event

		if !job || !status || !event
			json = {"success" => "false"}
		end

		event.run_event(job, status.id)
		
		respond_to do |format|
			format.json { render json: json }
		end
	end

	def check_key
		api_key = params[:api_key]
		if api_key != DigFlow::Application.config.api_key 
			render json: nil
		end
	end

end