import Ember from 'ember';

export default Ember.Controller.extend({
  meta: {},
  lastFlowStepArray: Ember.computed('model.last_flow_step', function() {
    var array = Ember.A();
    array.pushObject(this.get('model.last_flow_step'));
    return array;
  }),
  abortedAt: Ember.computed('model.aborted_at', function(){
    if (this.get('model.aborted_at')) {
      return moment(this.get('model.aborted_at')).format("YYYY-MM-DD HH:mm:ss");
    } else {
      return "";
    }
  }),

  startedAt: Ember.computed('model.started_at', function(){
    if (this.get('model.started_at')) {
      return moment(this.get('model.started_at')).format("YYYY-MM-DD HH:mm:ss");
    } else {
      return "";
    }
  }),

  finishedAt: Ember.computed('model.finished_at', function(){
    if (this.get('model.finished_at')) {
      return moment(this.get('model.finished_at')).format("YYYY-MM-DD HH:mm:ss");
    } else {
      return "";
    }
  }),

  canStart: Ember.computed('meta.can_start', 'disable', function() {
    if(this.get('meta.can_start') && !this.get('disable')) {
      return true;
    } else {
      return false;
    }
  }),
  
  canStop: Ember.computed('meta.can_stop', 'disable', function() {
    if(this.get('meta.can_stop') && !this.get('disable')) {
      return true;
    } else {
      return false;
    }
  })
});
