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
        *  [COPY_FILE] (#copy_file)
        *  [COPY_FOLDER] (#copy_folder)
        *  [MOVE_FOLDER] (#move_folder)
        *  [DELETE_JOB_FILES] (#delete_job_files)
        *  [CHANGE_PACKAGE_LOCATION] (#change_package_location)
        *  [COLLECT_JOB_METADATA] (#collect_job_metadata)
        *  [CREATE_FORMAT] (#create_format)
        *  [CREATE_METS_FILE] (#create_mets_file)
        *  [CREATE_GUPEA_PACKAGE] (#create_gupea_package)

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
*****
### Running processes
A *Running process* has specific tasks which it will conduct when started. Such task can consist of anything, e.g. copying folders, creating files, deleting files, importing data et.c.  
Running processes are started by the Queue Manager, and only one process can run at any one time.
*****
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
*****
#### COPY_FOLDER
##### Description 
Copies a folder to given location.
##### Parameters
**source_folder_path** (Path) - Path of source folder  
**destination_folder_path** (Path) - Path of destination folder (including the copied folder, i.e. not its parent)  
**format** (Format string, e.g. '%04d' for 0001.jpg) (Not mandatory) - Tells new format of file names after being copied, can be omitted if filenames should remain the same.
##### Expected outcome
Source folder contents are copied to the destination folder, with new filenames if **format** is given.
##### Examples
**Example 1:** A folder of tif files is copied to the job folder, and its content files renamed according to "0001.tif, 0002.tif...".
```json
{
    "step": 60,
    "process": "COPY_FOLDER",
    "description": "Copy tif files into job",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "source_folder_path": "MACHINE1:/scans/%{job_id}/tif",
      "destination_folder_path": "PROCESSING:/%{job_id}/tif",
      "format": "%04d"
    }
  },
```
*****
#### MOVE_FOLDER
##### Description 
Moves a folder to given location.
##### Parameters
**source_folder_path** (Path) - Path of source folder  
**destination_folder_path** (Path) - Path of destination folder (including the copied folder, i.e. not its parent)  
**format** (Format string, e.g. '%04d' for 0001.jpg) (Not mandatory) - Tells new format of file names after being copied, can be omitted if filenames should remain the same.
##### Expected outcome
Source folder contents are copied to the destination folder, with new filenames if **format** is given. Source folder is then deleted.
##### Examples
**Example 1:** A folder of tif files is moved to the job folder, and its content files renamed according to "0001.tif, 0002.tif...".
```json
{
    "step": 60,
    "process": "MOVE_FOLDER",
    "description": "Move tif files into job",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "source_file_path": "MACHINE1:/scans/%{job_id}/tif",
      "destination_file_path": "PROCESSING:/%{job_id}/tif",
      "format": "%04d"
    }
  },
```
*****
#### DELETE_JOB_FILES
##### Description 
Deletes a job folder with the job id as name from given parent path.
##### Parameters
**job_parent_path** (Path) - Path of parent directory of job folder  
##### Expected outcome
If there is a folder named after the jobs id in the given directory, it should be deleted.
##### Examples
**Example 1:** A processing folder (STORE:/12345) for the job is no longer needed, and should be deleted.
```json
{
    "step": 60,
    "process": "DELETE_JOB_FILES",
    "description": "Delete processing folder for job",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "job_parent_path": "PROCESSING:/"
    }
  },
```
*****
#### CHANGE_PACKAGE_LOCATION
##### Description 
Changes the current default location for the job files, which decides which files are to be displayed in the DFlow interface.
##### Parameters
**job_parent_path** (Path) - New path for job files
##### Expected outcome
The package location for the job is updated, and the files showin in the interface should reflect the change.
##### Examples
**Example 1:** A job has been moved from PACKAGING to STORE, which should be reflected in DFlow.
```json
{
    "step": 60,
    "process": "CHANGE_PACKAGE_LOCATION",
    "description": "Change package location to STORE",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "new_package_location": "STORE:/{package_name}"
    }
  },
```
*****
#### COLLECT_JOB_METADATA
##### Description 
Collects metadata from a given file folder, storing file names and file count as metadata for the job in DFlow.
##### Parameters
**folder_path** (Path) - Path of files from which to derive metadata, presumable a folder containing master images.  
**filetype** (Extension, e.g. tif, jpg) - The extension of the files in given folder, to be able to seperate possible extra files (thumbs.db, .DS_STORE, .tmp et.c.)
##### Expected outcome
The metadata for the job will be updated to contain the images within the given folder.
##### Examples
**Example 1:** A jobs master files are contained in the **tif** folder, and should be the base for the job's image metadata.
```json
{
    "step": 60,
    "process": "COLLECT_JOB_METADATA",
    "description": "Get image metadata from master images",
    "goto_true": 70,
    "goto_false": null,
    "params": {
      "folder_path": "PROCESSING:/{job_id}/tif",
      "filetype": "tif"
    }
  },
```
*****
#### CREATE_FORMAT
##### Description 
Creates a new image format using ImageMagick with given parameters.
##### Parameters
**source_folder_path** (Path) - Path of folder containing files to create new image format from.  
**destination_folder_path** (Path) - Path of folder where resulting files should end up.  
**to_filetype** (Extension, e.g. tif, jpg) - Extension of generated files.  
**format** (String, ImageMagick convert parameter string) - A valid ImageMagick parameter string for the **convert** command, saying which arguments should apply to the new format.
##### Expected outcome
A new format is created using the given formatting parameters.
##### Examples
**Example 1:** A jobs master files should be converted to jpg derivatives.
```json
 {
    "step": 70,
    "process": "CREATE_FORMAT",
    "description": "Create jpg files from master files",
    "goto_true": 75,
    "goto_false": null,
    "params": {
        "source_folder_path": "PROCESSING:/%{job_id}/mst/tif_lzw",
         "destination_folder_path": "PROCESSING:/%{job_id}/web/jpg",
         "to_filetype": "jpg",
         "format": "-unsharp 0.3x0.5+4.0+0 -level 10%,93% -quality 94"
    }
},
```
*****
#### CREATE_METS_FILE
##### Description 
Creates a METS-file for the current job using given parameters.
##### Parameters
**job_folder_path** (Path) - Path of job folder for which to create the METS-file.  
**mets_file_path** (Path) - Path of the reulting mets_file including filename.  
**formats_required** (List string, e.g. ("master, web, alto")) - List of formats included in the mets file, which will also be required to exist with a 1:1 ratio to the jobs page_count for the process to validate. Formats will be assumed to reside in the root of the job folder.  
**files_required** (List string, e.g. "pdf/%{package_name}.pdf, xml/%{package_name}.xml") - List of files included in the mets file, which also will have to exist for the process to validate.  
**creator_name** (String) - Name of institution to insert into CREATOR field.  
**creator_sigel** (String, sigel e.g. 'Gdig') - Sigel of institution to insert into CREATOR field.  
**archivist_name** (String) (not mandatory) - Name of institution to insert into ARCHIVIST field. Defaults to **creator_name** if not assigned.  
**archivist_sigel** (String, sigel e.g. 'Gdig') (not mandatory) - Sigel of institution to insert into ARCHIVIST field. Defaults to **creator_sigel** if not assigned.  
**copyright_true_text** (String) (not mandatory) - String representation for a copyrighted job. Defaults to 'copyrighted' if not assigned.  
**copyright_false_text** (String) (not mandatory) - String representaion for a non copyrighted job. Defaults to 'pd' if not assigned.  
**require_physical** (true/false) (not mandatory) - If true, requires that the **physical** metadata is set for all image objects within the job.  
**validate_group_names** (true/false) (not mandatory) - If true, requires validation of group names against existing group names according to the **source xml** of the job.
##### Expected outcome
A mets file is created consisting the given formats and files.
##### Examples
**Example 1:** A mets-file should be created for a job.
```json
 {
    "step": 70,
    "process": "CREATE_METS_FILE",
    "description": "Create METS-file",
    "goto_true": 75,
    "goto_false": null,
    "params": {
        "job_folder_path": "PACKAGING:/%{job_id}",
        "mets_file_path": "PACKAGING:/%{job_id}/%{package_name}_mets.xml",
        "formats_required": "web, jpg, alto",
        "files_required": "pdf/%{package_name}.pdf",
        "creator_name": "Gothenburg University Library, Digital Services",
        "creator_sigel": "Gdig"
    }
},
```
*****
#### CREATE_GUPEA_PACKAGE
**This process is specific for the GUB implementation of DFlow**  
##### Description 
Creates a post in GUPEA for job including a PDF-file.
##### Parameters
**gupea_collection** (String) - A string representing the GUPEA collection to which the post should be uploaded.
**pdf_file_path** (Path) - Path of pdf file to upload to GUPEA.
**gupea_folder_path** (Path) - Path of where to put folder of files from which GUPEA will import its data.
##### Expected outcome
A post is created in GUPEA, and a PublicationLog item is created in DFlow containing a reference to the GUPEA post.
##### Examples
**Example 1:** A job's PDF file should be uploaded to GUPEA
```json
 {
    "step": 220,
    "process": "CREATE_GUPEA_PACKAGE",
    "description": "CReate GUPEA post with PDF",
    "goto_true": 230,
    "goto_false": null,
    "params": {
      "gupea_collection": "2077/38764",
      "pdf_file_path": "STORE:/%{package_name}/pdf/%{package_name}.pdf",
      "gupea_folder_path": "GUPEA:/%{job_id}"
    }
  },
```
*****
