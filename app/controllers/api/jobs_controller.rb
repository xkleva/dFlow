

class Api::JobsController < ApplicationController
	before_filter :check_key

	# Returns the metadata for a given job
	def job_metadata
		response = {}
		begin
			job = Job.find(params[:job_id])
			response = JSON.parse(job.metadata)
			response[:msg] = "Success"
		rescue
			response[:msg] = "Fail"
		end
		render json: response
	end

	# Updates metadata for a specific key
	def update_metadata
		response = {}
		begin
			job = Job.find(params[:job_id])
			job.update_metadata_key(params[:key], params[:metadata])
			response[:msg] = "Success"
		rescue
			response[:msg] = "Fail"
		end
		render json: response
	end

	# Returns source object xml data of a job
	def mets_data
		mets_data = {}
		begin
			job = Job.find(params[:job_id])
			created_at = job.created_at.strftime("%FT%T")
			mets_data[:xml_type] = job.source_object.xml_type(job)
			mets_data[:xml_data] = job.source_object.xml_data(job)
			mets_data[:mets_extra_dmdsecs] = job.source_object.mets_extra_dmdsecs(job, created_at)
			mets_data[:advanced_covers] = job.source_object.advanced_covers?
			mets_data[:msg] = "Success"
		rescue
			mets_data[:msg] = "Fail"
		end
		render json: mets_data
	end

	# Returns source object dmdid attribute value
	def mets_dmdid_attribute
		response = {}
		begin
			job = Job.find(params[:job_id])
			group = params[:group]
			response[:dmdid] = job.source_object.mets_dmdid_attribute(job, group)
			response[:msg] = "Success"
		rescue
			response[:msg] = "Fail"
		end
		render json: response
	end

	# Returns a job to work on for given process unless too many processer are already running 
	def process_request
		process_id = params[:process_id]
		response = {}
		job = nil
		
		process_config = Rails.configuration.process_configs.select{|x| x[:process] == process_id}.first
		if process_config.nil?
			response[:msg] = "Fail"
			response[:error] = "Process_id '#{process_id}'' is unknown"
			render json: response
			return
		end

		allowed_processes = process_config[:allowed_processes]
		processing = 0

		# Check if the allowed amount of processes are already running
		process_config[:block_statuses].each do |status|
			processing += Job.where(:quarantined => false).where(:status_id => Status.find_by_name(status).id).size
		end
		# Find job that matches start_status
		job = Job.where(:quarantined => false).where(:status_id => Status.find_by_name(process_config[:start_status]).id).first
		if processing >= allowed_processes
			response[:msg] = "Fail"
			response[:error] = "Too many processes running: (#{processing})"
		elsif job.nil?
			response[:msg] = "Fail"
			repsonse[:error] = "No job is in line for processing (#{process_id})"
		else
			response[:msg] = "Success"
			response[:job_id] = job.id
		end
			
		render json: response
	end


		##OLD METHODS
	#Finds the next job in line with a certain status
	def get_next_w_status
		status = params[:status]

		#Check if any job is currently in mets production
		if status == "mets_control_end"
			if !Job.where(:quarantined => false).where(:status_id => Status.find_by_name("mets_production_begin").id).empty?
				return nil
			end
		end

		#Check if any job is currently in mets control
		if status == "waiting_for_mets_control_begin"
			if !Job.where(:quarantined => false).where(:status_id => Status.find_by_name("mets_control_begin").id).empty?
				return nil
			end
		end

		job = Job.where(:quarantined => false).where(:status_id => Status.find_by_name(status).id).first
		respond_to do |format|
			format.json { render json: job }
		end
	end

	#Puts a job in quarantine with a given message
	def quarantine_job
		job = Job.find(params[:job_id])
		message_key = params[:message_key]
		job.set_quarantine(I18n.t("mets.errors.#{message_key}"))

		respond_to do |format|
			format.json { render json: {"success" => "true"} }
		end
	end

	#Returns images from /work/small (used by dScribe)
	def get_small_work_images
		job = Job.find(params[:job_id])
		startnr = params[:startnr]
		count = params[:count]
		image_folder = Pathname.new(job.job_processing_folder.to_s + "/work/small")
		response = {}
		image_files = []
		if !image_folder.exist? || !image_folder.directory?
			response[:error] = "#{image_folder} is not a valid directory"
		else
			image_files = job.get_file_range_info(image_folder, (startnr.to_i...(startnr.to_i+count.to_i)))
		end
		response[:image_files] = image_files

		respond_to do |format|
			format.json { render json: response }
		end
	end


	# Updates page info for given image files
	def update_page_info
		job = Job.find(params[:job_id])
		image_files = params[:image_files]
		params[:image_files].each do |page_info|
			job.update_page_info(page_info[1]["filename"], page_info[1]["cropframe"])
		end
		if !job.save
			render text: "Error", status: 500
			return
		end

		respond_to do |format|
			msg = { :status => "ok", :message => "Success!", :html => "<b>...</b>" }
		    format.json  { render :json => msg } # don't do msg.to_json
		end
	end

	def check_key
		api_key = params[:api_key]
		if api_key != DigFlow::Application.config.api_key 
			render json: {msg: "Fail"}
		end
	end

	private 
	# Sorts a list of files based on filename
	def sort_files(files)
		files.sort_by { |x| x.basename.to_s[/^(\d+)\./,1].to_i }
	end

end