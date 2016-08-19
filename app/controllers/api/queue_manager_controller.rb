class Api::QueueManagerController < ApplicationController
  before_filter -> { validate_rights 'manage_jobs' }
  
  def index
    qm = QueueManagerPid.running_qm
    qms = []
    qms << qm if qm
    @response[:queue_managers] = qms
    @response[:meta] = {
      can_start: QueueManagerPid.can_start?,
      can_stop: QueueManagerPid.can_stop?,
      log_output: QueueManagerPid.fetch_log_lines
    }
    render_json
  end
  
  def create
    if QueueManagerPid.can_start?
      QueueManagerPid.execute_queue_manager!
    end
    @response[:queue_manager] = {}
    render_json
  end
  
  def destroy
    qm = QueueManagerPid.running_qm
    if qm
      qm.abort
    end
    @response[:queue_manager] = qm
    render_json
  end
end
