import Ember from 'ember';
import ENV from 'd-flow-ember/config/environment';

export default Ember.Controller.extend({

  session:     Ember.inject.service(),
  i18n:        Ember.inject.service(),

  isPollingStarted: Ember.computed.gt('pollCounter', 0),

  actions: {

    // If the user has supplied valid dates, and agreed to the generated file name,
    // createJobDataForStatisticsFile tells (indirectly) the backend through the 
    // statistics api to run the EXPORT_JOB_DATA_FOR_STATISTICS process. The process 
    // runs a database query to generate the info for the job data for statistics Excel 
    // file, and then creates the file. While createJobDataForStatisticsFile waits for 
    // the file to get ready for download, it polls the server through the statistics 
    // api with the process id serving as file id. When the server returns build state
    // READY_FOR_DOWNLOAD, the file download button is displayed on screen and the 
    // user can download the file through the statistics api, i.e. outside of the 
    // control of this action.

    createJobDataForStatisticsFile: function(startDate, endDate) {

      if (!this.validateDateInputs(startDate, endDate)) { return }

      let fileName  = this.buildFileName (startDate, endDate);
      let sheetName = this.buildSheetName(startDate, endDate);

      if (!confirm(this.buildConfirmMessage(fileName))) { return }

      // The date inputs are valid, the setup is done, and the user wants to continue...

      this.prepareAttributesForNewRun();

      // Send a request (indirectly) to the backend to start building the file...
      let that  = this;
      this.store.save('statistics', {
        process_name: 'EXPORT_JOB_DATA_FOR_STATISTICS',
        params: {
          start_date: startDate,
          end_date:   endDate,
          file_name:  fileName,
          sheet_name: sheetName
        }
      })
        // ... and poll for a file ready for download status
        .then(
           function(response) {
             console.log(response);
             that.pollToCheckIfFileIsReadyForDownload(response.id);
           }, 
           function(error) {
             that.set('error', error.error);
             that.set('statusMessage', this.t('statistics.file_creation_error'));
           });
    }
  },

  prepareAttributesForNewRun: function(){
      this.set('fileCreationButtonDisabled', true);
      this.set('statusMessage', '');
      this.set('fileReadyForDownload', false);
      this.set('fileUrl', '');
      this.set('pollCounter', 0);
  },

  // Polls the backend asking if the file is ready for download. The process id
  // (integer) is used as file id, i.e. the file does not have an id of its own
  pollToCheckIfFileIsReadyForDownload: function(processAndFileId, interval = this.get('pollInterval')) {
    // If we know that the file is ready for download or we have encountered an error, we stop polling
    if (this.get('fileReadyForDownload') || (this.get('error') != null)) { return }
    // Otherwise we poll the backend...
    this.checkIfFileIsReadyForDownload(processAndFileId);
    this.increasePollCounter();
    // ... and schedule a recursive call
    Ember.run.later(this, 
                    function() { this.pollToCheckIfFileIsReadyForDownload(processAndFileId, interval); }, 
                    interval);
  },

  increasePollCounter: function(){
    this.set('pollCounter', this.get('pollCounter') + 1);
  },

  // Check if the file is ready for download, and set relevant attributes if it is,
  // in order to stop the polling and prepare the user interface for download
  checkIfFileIsReadyForDownload: function(processAndFileId) {
    let that = this;
    this.store.find('statistics', processAndFileId, {})
      .then(
         function(response) {
           that.setStatusMessageFromBuildStatus(that, response.build_status);
           if (response.build_status === 'READY_FOR_DOWNLOAD') {
             that.set('fileCreationButtonDisabled', false)
             that.set('fileReadyForDownload', true);
             let token = that.get('session.data.authenticated.token');
             that.set('fileUrl', ENV.APP.serviceURL.concat('/api/statistics/download/' + processAndFileId,
                                                           '?token=' + token));
           }
         },
         function(error) {
           that.set('error', error.error);
           that.set('statusMessage', this.t('statistics.file_creation_error'));
         });
  },

  // Set status messages based on the build status names coming from the backend
  setStatusMessageFromBuildStatus: function(that, buildStatus) {
    let statusMessage = that.get('statusMessage');
    statusMessage = buildStatus  === 'QUERYING_DATABASE' && 
                      String(statusMessage).startsWith(String(this.tbs('QUERYING_DATABASE'))) ?  
                    statusMessage + '.' : 
                    this.tbs(buildStatus) ;
    that.set('statusMessage', statusMessage);
  },

  // [T]ranslate [b]uild [s]tatus names coming from the backend
  tbs(buildStatus){
    switch (buildStatus){
      case 'INITIALIZING'      : return this.t('statistics.build_status.initializing');
      case 'QUERYING_DATABASE' : return this.t('statistics.build_status.querying_database');
      case 'DATABASE_QUERIED'  : return this.t('statistics.build_status.database_queried');
      case 'WORKBOOK_BUILT'    : return this.t('statistics.build_status.workbook_built');
      case 'XLS_DATA_OUTPUT'   : return this.t('statistics.build_status.xls_data_output');
      case 'READY_FOR_DOWNLOAD': return this.t('statistics.build_status.ready_for_download');
      default                  : return '';
    }
  },

  validateDateInputs: function(startDate, endDate) {

    // Validate the start date 
    if (!moment(startDate, this.get('dateFormat'), true).isValid()){
      this.set('validationErrorStartDate', true);
      alert(this.t('statistics.start_date_alert'));
      return false;
    }
    this.set('validationErrorStartDate', false);

    // Validate the end date 
    if (!moment(endDate, this.get('dateFormat'), true).isValid()){
      this.set('validationErrorEndDate', true);
      alert(this.t('statistics.end_date_alert'));
      return false;
    }
    this.set('validationErrorEndDate', false);

    // Both the dates are correct
    return true;
  },

  // Build a file name for the Excel file 
  // e.g. "dFlow-statistikdata_2019-01-01_till_2019-01-31_(uttaget_2019-03-26_14.09.15).xls"
  buildFileName: function(startDate, endDate) {
      let now = moment().format(this.t('statistics.file_name.now_format').string);
      let fileNameParts = [];
      fileNameParts[0] = this.t('statistics.file_name.header');
      fileNameParts[1] = startDate;
      fileNameParts[2] = this.t('statistics.file_name.until');
      fileNameParts[3] = endDate;
      fileNameParts[4] = "(" + this.t('statistics.file_name.extracted');
      fileNameParts[5] = now + ").xls";
      return fileNameParts.join('_');
  },

  // Build a message that asks the user to confirm that the creation of a file with the 
  // given filename should proceed. The reason for having such a dialog is not the
  // naming of the file, but to prevent that accidental clicking of the create file button 
  // will lead to unnecessary activity on the server and waiting times for the user.
  // A request may take a long time to fulfill.
  buildConfirmMessage: function(fileName) {
      return ["\n" + this.t('statistics.confirm_create_file'),
              "\"" + fileName + "\"\n\n"].join("\n\n");
  },

  // Build a sheet name for the (only) sheet in the workbook
  // e.g. "2019-01-01 till 2019-01-31"
  buildSheetName: function(startDate, endDate) {
      return [startDate, this.t('statistics.file_name.until'), endDate].join(' ');
  },

  // Shortcut for translation
  t(translation_node){
    return this.get('i18n').t(translation_node);
  }

});
