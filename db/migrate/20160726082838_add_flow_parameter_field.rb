class AddFlowParameterField < ActiveRecord::Migration
  def change
    add_column :jobs, :flow_parameters, :text, default: ""
  end
end
