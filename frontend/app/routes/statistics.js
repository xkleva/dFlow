import Ember from 'ember';

export default Ember.Route.extend({

  setupController: function(controller, model) {

	// Tweakable "constant"
	controller.set('pollInterval', 1000); // milliseconds
	
	// Non-tweakable "constant"
	controller.set('dateFormat'  , 'YYYY-MM-DD');

	// Initialization
	controller.set('pollCounter' , 0);
	controller.set('error'       , null);

  }
});