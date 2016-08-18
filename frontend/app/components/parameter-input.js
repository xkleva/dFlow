import Ember from 'ember';

export default Ember.Component.extend({
  prompt: true,
  initValue: function(){
    this.set('value', this.get('values.' + this.get('parameter.name')));
  }.on('init'),

  isRadio: Ember.computed.equal('parameter.type', 'radio'),
  isText: Ember.computed.equal('parameter.type', 'text'),

  valueObserver: Ember.observer('value', function(){
    this.set('values.' + this.get('parameter.name'), this.get('value'));
  }),

  optionList: Ember.computed('parameter.options', function() {
    return this.get('parameter.options').map(function(option) {
      if(typeof(option) === "string") {
        return {
          value: option,
          label: option
        }
      } else {
        return option;
      }
    });
  })
});
