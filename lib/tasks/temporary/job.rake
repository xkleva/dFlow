namespace :job do
  desc "Creates file metadata info from master files"
  task :create_file_metadata_info => :environment do
    require 'pp'
    Job.where(state: "FINISH").each do |job|
      path = job.package_dir
      name = job.package_name
      source_dir = "STORE:#{path}/#{name}/master"
      begin
        res = DfileApi.get_file_metadata_info(source_dir: source_dir)
        puts "Update scanner info #{job.id}: #{res.inspect}"
        job.update_attributes({scanner_make: res["make"], scanner_model: res["model"], scanner_software: res["software"]})
      rescue StandardError => e
        puts "No scanner info  #{job.id}: #{e}"
      end
    end
  end
end
