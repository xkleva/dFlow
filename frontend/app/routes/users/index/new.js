import Ember from 'ember';

export default Ember.Route.extend({
  model: function() {
    return {}; // Data to include in create form
  },
  setupController: function(controller, model) {
    controller.set('model', model);
    controller.set('error', null);
  },
  actions: {
    createUser: function(model) {
      var that = this; // To be used in nested functions
      this.store.save('user', model).then(
        // Success function
        function() {
          that.send('refreshModel'); // Refresh children of current model
          that.transitionTo('users.index');
        },
      // Failed function
        function(errorObject) {
          that.controller.set('error', errorObject.error);
        }
      );
    }
  }
});
