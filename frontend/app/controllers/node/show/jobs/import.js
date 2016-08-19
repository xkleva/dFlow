import Ember from 'ember';

export default Ember.Controller.extend({
  application: Ember.inject.controller(),
  node: Ember.inject.controller('node/show'),
  copyrightSelection: Ember.computed.alias('application.copyrightSelection'),
  flowSelection: Ember.computed.alias('application.flowSelection'),
  sourceSelection: Ember.computed.alias('application.sourceSelection'),
  importId: null,

  isAborted: Ember.computed.equal('progress.state', 'ABORTED'),
  isDone: Ember.computed.equal('progress.state', 'DONE'),
  isRunning: Ember.computed.equal('progress.state', 'RUNNING'),
  jobError: Ember.computed.equal('progress.action', 'JOB_ERROR'),
  
  currentFlow: Ember.computed('model.flow_id', function(){
    return this.get('application.flows').findBy('id', this.get('model.flow_id'));
  }),

  actions: {
    importFile: function(model) {
      var that = this;
      this.set('progress', null);
      this.store.save('script', {
        process_name: "IMPORT_JOBS",
        params: {
          copyright: model.copyright,
          treenode_id: that.get('node.model.id'),
          flow_id: model.flow_id,
          source_name: model.source_name,
          file_path: model.file_path,
          flow_parameters: model.flow_parameters
        }
      }).then(function(response) {
        that.set('process_id', response.id);
        that.send('updateStatus', response.id);
      }, function(error) {
        that.set('error', error.error);
      });
    },
    updateStatus: function(process_id) {
      var that = this;
      this.store.find('script', process_id).then(function(response) {
        that.set('progress', response);
        var fetch_again = true;
        if(response.state === "DONE") {
          fetch_again = false;
          that.set('preventUpdate', true);
          that.send('refreshModel', that.get('node.model.id'));
        }
        if(response.state === "ABORTED") {
          fetch_again = false;
        }
       
        if(fetch_again) {
          Ember.run.later(function() {
            that.send('updateStatus', process_id);
          }, 1000);
        }
      });
    }
  }
});
