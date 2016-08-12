import Ember from 'ember';
import InViewportMixin from 'd-flow-ember/mixins/in-view-port';
import Item from 'd-flow-ember/models/item';
import ENV from 'd-flow-ember/config/environment';

export default Ember.Component.extend(InViewportMixin, {
  session: Ember.inject.service(),
  store: Ember.inject.service(),
  init() {
    var that = this;
    var token =  this.get('session.data.authenticated.token');
    this.store.find('thumbnail', '?source_dir=PROCESSING:/78&source=master&image=' + this.get('imageMetadata.num') + '&token=' + token).then(function(response){
      var item = Item.create({
        small: response.thumbnail,
        tiny: response.thumbnail,
        title: that.get('imageMetadata.num'),
        selection: {x: 20, y: 20, w: 500, h: 800},
        logical: that.get('imageMetadata.page_content'),
        physical: that.get('imageMetadata.page_type')
      })
      that.set('item', item);
    })

    this._super();
  },
  tagName: 'div',
  classNames: ['inactive-image'],
  classNameBindings: ['enteredViewport:entered-viewport', 'item.isAlone:col-xs-12:col-xs-6'],
  activeFrame: false,

  mouseEnter: function(){
    this.set('activeFrame', true);
  },
  mouseLeave: function(){
    this.set('activeFrame', false);
  },

  actions: {
    copyFrame: function(fromItem, toItem){
      toItem.set('selection', Ember.copy(fromItem.get('selection')));
    },
    setPhysical: function(item, physical){
      item.set('physical', physical);
    }
  }
});
