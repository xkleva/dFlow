class AddColumnCommentToFlowSteps < ActiveRecord::Migration
  def change
    add_column :flow_steps, :comment, :text  	
  end
end
