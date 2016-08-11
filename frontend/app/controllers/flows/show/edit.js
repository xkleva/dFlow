import Ember from 'ember';

export default Ember.Controller.extend({
  modes: ['tree','code'],
  steps_mode: 'code',
  parameters_mode: 'code',
  folder_paths_mode: 'code',

  actions: {
    save(model) {
      var that = this;
      this.set('savingMessage', 'Sparar...');
      this.store.save('flow', model).then(function(){
        that.set('savingMessage', 'Sparat!');
        that.send('refreshApplication');
      },
      function(response){
        that.set('errors', response.error.errors);
        that.set('savingMessage', 'Kunde inte spara!');
      }); 
    }

  }

});
