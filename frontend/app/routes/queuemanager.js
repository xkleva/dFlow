import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return this.store.find('queue_manager');
  },
  updateStatus: function(controller) {
    var that = this;
    if(controller.get('updateStatus')) {
      Ember.run.later(function() {
        that.store.find('queue_manager').then(function(model) {
          controller.set('model', model[0]);
          if(model.meta) {
            controller.set('meta', model.meta);
          }
          if(controller.get('disable') > 0) {
            controller.set('disable', controller.get('disable') - 1);
          }
        });
        that.updateStatus(controller);
      },1000);
    }
  },
  setupController: function(controller, model) {
    var that = this;
    controller.set('model', model[0]);
    if(model.meta) {
      controller.set('meta', model.meta);
    }
    controller.set('updateStatus', true);
    controller.set('disable', 0);
    this.updateStatus(controller);
  },
  resetController: function(controller) {
    console.log("resetController");
    controller.set('updateStatus', false);
  },
  actions: {
    startQueueManager: function() {
      if (confirm('Är du säker på att du vill starta köhanteraren?')) {
        var that = this;
        this.store.save('queue_manager', {}).then(function() {
          that.controller.set('disable', 3);
        });
      }
    },
    stopQueueManager: function(pid) {
      if (confirm('Är du säker på att du vill stoppa köhanteraren?')) {
        var that = this;
        this.store.destroy('queue_manager', pid).then(function() {
          that.controller.set('disable', 3);
        });
      }
    }
  }
});
