import Ember from 'ember';

export default Ember.Component.extend({

  actions: {
    generatePageTypes() {
      var that = this;
      this.get('packageMetadata.images').forEach((image, index) =>{
        var even = 'Undefined';
        var odd = 'Undefined';
        var currIndex = index;
        if (this.get('startNr')) {
          if (index < this.get('startNr')-1) {
            return;
          }
          currIndex = index - this.get('startNr') + 1;
        }
        switch (this.get('sequence')) {
          case 'right-left':
            even = 'RightPage';
            odd = 'LeftPage';
            break;
          case 'left-right':
            even = 'LeftPage';
            odd = 'RightPage';
            break;
          case 'right':
            even = 'RightPage';
            odd = 'RightPage';
            break;
          case 'left':
            even = 'LeftPage';
            odd = 'LeftPage';
            break;
          default:
            even = 'Undefined';
            odd = 'Undefined';
        }
        if (currIndex % 2 === 0) {
          Ember.set(image, 'page_type', even);
        } else {
          Ember.set(image, 'page_type', odd);
        }
      })
    }
  }
});
