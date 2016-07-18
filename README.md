# DFlow

DFlow is a Ruby-On-Rails Application, built to support workflows for large digitizing projects.

## Table of Contents

* [Processes] (#processes)
    *  [Making an API-request] (#making-an-api-request)
    *  [Triggered processes] (#triggered-processes)
        * [CONFIRMATION] (#confirmation)
    *  [Waiting processes] (#waiting-processes)
        *  [WAITFOR_FILES] (#waitfor_files)
        *  [WAITFOR_FILE] (#waitfor_file)
    *  [Running processes] (#running-processes)

## Processes
A process is a potiential step which can be used in a workflow. These processes can be triggered manually & via API-request, or through the built in Queue Manager.
### Making an API-request
Observe that you will have to define **api-keys** to be able to use the API.  
For an external service to be able to control the workflow steps, API-requests can be made. The requests are built using the following format:  
`http://dflow-example.com/api/process/<job_id>?step=<step_nr>&status=[start, success, fail, progress]&msg=<String (e.g. progress message, error message)>`

**Example 1:** Finishing flow step **30** for job with id **12345**  
`http://dflow-example.com/api/process/12345?step=30&status=success`

**Example 2:** Starting flow step **50** for job with id **12345**  
`http://dflow-example.com/api/process/12345?step=50&status=start`

**Example 3:** Reporting progress for flow step **20** for job with mid **12345**  
`http://dflow-example.com/api/process/12345?step=50&status=progress&msg='In progress!'`

**Example 4:** Reporting fail for flow step **20** for job with mid **12345**  (Will also place job in **quarantine**)  
`http://dflow-example.com/api/process/12345?step=50&status=fail&msg='Process failed!'`

### Triggered processes
A *Triggered* flow step has to be called to be completed, either through interaction with the DFlow interface or via API-request.
*****
#### CONFIRMATION
##### Description 
Is meant to be used as a confirmation trigger that the current step is completed. The trigger can either be called by a manual press of a button inside DFlow, or through an API-request form an external service.
##### Parameters
**manual** (true / false) - If true, a confirmation button will be visible inside DFlow.
**msg** (String, e.g. "Operation done!")
##### Expected outcome
This process only finishes the current flow step
##### Examples
**Example 1:** The manual task of reviewing a document needs a place in the workflow. When done, the user klicks a confirmation button in DFlow to move the workflow to the next step in the process.
```json
{
    "step": 60,
    "process": "CONFIRMATION",
    "description": "Review document",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "manual": true,
      "msg": "Document is reviewed!"
    }
  },
```
**Example 2:** The process of creating jpg-files is delegated to an external software. The external software makes an API-request to DFlow to alert the workflow that it is done.
```json
{
    "step": 60,
    "process": "CONFIRMATION",
    "description": "External application: Create JPG files",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "manual": false
    }
  },
```
*****
### Waiting processes
A *waiting process* works much like a triggered process, in that it's only function is to finish the current flow step and move to the next one. The trigger in this case however, is its **condition**, which can consist of waiting for a **specific file to exist** or a **specific number of files** to exist, for example.  
Waiting processes are run by the internal Queue Manager, and shares queue with all other waiting processes in it.
*****
#### WAITFOR_FILE
##### Description 
Waits for a given file to exist before finishing.
##### Parameters
**file_path** (Path) - Path of file to look for
##### Expected outcome
The process keeps repeating until given file is found.
##### Examples
**Example 1:** An external process has created an XML-file in the job folder, which needs to exist for the workflow to proceed.
```json
{
    "step": 60,
    "process": "WAITFOR_FILE",
    "description": "Check if file1.xml exists in job folder!",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "file_path": "PROCESSING:/%{job_id}/xml/file1.xml"
    }
  },
```
*****
#### WAITFOR_FILES
##### Description 
Waits until given folder contains the given amount of files of a given type before finishing.
##### Parameters
**folder_path** (Path) - Path of directory in which to look for files
**filetype** (File extension, e.g. tif, jpg, xml) - Extension of files to look for
**count** (Number) - Number of files to look for
##### Expected outcome
The process keeps repeating until the given number of files are found.
##### Examples
**Example 1:** An external process creates jpg files, and the workflow must wait until all files are created before proceeding.
*****
```json
{
    "step": 60,
    "process": "WAITFOR_FILES",
    "description": "Check if all jpg files have been created",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "folder_path": "PROCESSING:/%{job_id}/jpg/",
      "filetype": "jpg",
      "count": "%{page_count}"
    }
  },
```
### Running processes
A *Running process* has specific tasks which it will conduct when started. Such task can consist of anything, e.g. copying folders, creating files, deleting files, importing data et.c.  
Running processes are started by the Queue Manager, and only one process can run at any one time.
#### COPY_FILE
##### Description 
Copies a file to given location and filename.
##### Parameters
**source_file_path** (Path) - Path of source file
**destination_file_path** (Path) - Path of destination file (including filename)
##### Expected outcome
Source file is copied to destination file
##### Examples
**Example 1:** An external jpg is copied to the job folder
```json
{
    "step": 60,
    "process": "COPY_FILE",
    "description": "Copy external jpg into job",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "source_file_path": "CONFIGURATION:/placeholders/jpg/placeholder1.jpg",
      "destination_file_path": "PROCESSING:/%{job_id}/jpg/0000.jpg"
    }
  },
```
#### COPY_FOLDER
##### Description 
Copies a folder to given location.
##### Parameters
**source_folder_path** (Path) - Path of source folder
**destination_folder_path** (Path) - Path of destination folder (including the copied folder, i.e. not its parent)
##### Expected outcome
Source folder contents are copied to the destination folder.
##### Examples
**Example 1:** A folder of tif files is copied to the job folder.
```json
{
    "step": 60,
    "process": "COPY_FOLDER",
    "description": "Copy tif files into job",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "source_file_path": "MACHINE1:/scans/%{job_id}/tif",
      "destination_file_path": "PROCESSING:/%{job_id}/tif"
    }
  },
```
#### MOVE_FOLDER
#### DELETE_JOB_FILES
#### CHANGE_PACKAGE_LOCATION
#### COLLECT_JOB_METADATA
#### CREATE_FORMAT
#### CREATE_METS_FILE
#### CREATE_GUPEA_PACKAGE
**This process is specific for the GUB implementation of DFlow**
