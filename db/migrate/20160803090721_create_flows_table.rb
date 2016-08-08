class CreateFlowsTable < ActiveRecord::Migration
  def change
    create_table :flows do |t|
      t.string :name
      t.text :description
      t.text :parameters, default: "[]"
      t.text :folder_paths, default: "[]"
      t.text :steps, default: "[]"
      t.boolean :active, default: true
      t.datetime :deleted_at, default: nil
      t.timestamps
    end

    add_column :flow_steps, :flow_id, :integer
    rename_column :jobs, :flow, :flow_name
    add_column :jobs, :flow_id, :integer

    workflows = APP_CONFIG["workflows"]
    workflows.each do |wf|
      Flow.create(name: wf['name'], parameters: wf['parameters'].to_json, steps: wf['steps'].to_json)
    end

    job_count = Job.all.count
    Job.all.each_with_index do |job, index|
      pp "Updating job nr #{index}/#{job_count} : #{job.id}"
      flow = Flow.find_by_name(job.flow_name)
      if flow
        job.update_attribute('flow_id', flow.id)
        job.flow_steps.each do |flow_step|
          flow_step.update_attribute('flow_id', flow.id)
        end
      else
        pp "Couldn't find flow #{job.flow_name} for id #{job.id}"
      end
    end

  end
end
