# DFlow

DFlow is a Ruby-On-Rails Application, built to support workflows for large digitizing projects.

## Table of Contents
* [Configuration Interface] (#configuration-interface)
* [Workflows] (#workflows)
    * [Workflow Parameters] (#workflow-parameters)
    * [Folder paths] (#folder-paths)
    * [Flow steps] (#flow-steps)
* [Processes] (#processes)
    *  [Using Variables] (#using-variables)
    *  [Making an API-request] (#making-an-api-request)
    *  [Triggered processes] (#triggered-processes)
        * [CONFIRMATION] (#confirmation)
        * [QUALITY_CONTROL] (#quality_control)
        * [ASSIGN_METADATA] (#assign_metadata)
    *  [Waiting processes] (#waiting-processes)
        *  [WAIT_FOR_FILES] (#wait_for_files)
        *  [WAIT_FOR_FILE] (#wait_for_file)
    *  [Running processes] (#running-processes)
        *  [COPY_FILE] (#copy_file)
        *  [COPY_FOLDER] (#copy_folder)
        *  [MOVE_FOLDER] (#move_folder)
        *  [DELETE_JOB_FILES] (#delete_job_files)
        *  [COLLECT_JOB_METADATA] (#collect_job_metadata)
        *  [CREATE_FORMAT] (#create_format)
        *  [CREATE_METS_FILE] (#create_mets_file)
        *  [CREATE_GUPEA_PACKAGE] (#create_gupea_package)
        *  [COMBINE_PDF_FILES] (#combine_pdf_files)
        *  [CREATE_LIBRIS_ITEM] (#create_libris_item)

## Configuration Interface
The configuration interface is accessible through `http://<host>/setup`. For a locally running instance, it is typically reached by `http://localhost:3000/setup`. The username and password are assigned at the top of `config/config_full.yml`.

Everything in the configuration interface simply creates a new version of `config/config_full.yml`, meaning that all changes can be made directly to the configuration file just as well as through the interface.

After **saving** though the interface, make sure the server is **restarted** (this will happen automatically on any production server using *Passenger*, but not on local instances), and the page manually reloaded. Otherwise the old data will be shown, and any subsequent changes will overwrite the previously made ones.
## Workflows
A workflow defines which steps a job goes through to be processed. A Workflow is built up of [Steps] (#flow-steps), which each points to a specific [Process] (#processes).
### Creating a workflow
Workflows are created through the interface under *Flows*. The button *Create new flow* will create a new flow with a generated name, which can be changed in the next step.
### Workflow name
The workflow name has to be unique, and the preferred convention is to use upper snake-case (e.g. MY_FLOW).
### Workflow parameters
A workflow can have any number of predefined parameters. These parameters get their values from user-input per job. This makes the workflow highly flexible, and reduces the need for having many almost-identical workflows when there are only small differences.

**Parameter options**
**name** (String, lower snake-case e.g. 'my_parameter') - The name of the parameter, decides what it will be called in the GUI, as well as how to call it from a flow step.
**info** (String) - A description, meant to be able to guide the user as to what the parameter means. (e.g. 'Assign the number of pages this job has')
**type** (Predefined input types, i.e. one of 'radio') - The type of input for the user.
**options** (List of values) - The list of values available when using a predefined input type such as 'radio'. The option elements can be assigned as simple strings, or as a Hash object containing the keys **value** and **label**. The label can then be used to explain the value when using a dropdown, for example.

**Example:** Defines one parameter 'processing_station' for the current flow, using a radio input.
```json
"parameters": [
      {
        "name": "processing_station",
        "info": "Which station was used",
        "type": "radio",
        "options": [
          "STATION1",
          "STATION2",
          {
            "value": "STATION3",
            "label": "This will select Station 3 for you"
          }
        ]
      }
    ]
```

### Folder paths
The folder paths define which folders the flow can possibly store files in. These folder paths are used for two functions:
1. **Listing files** - When listing files for a given job, DFlow looks through all given folder paths and displays the ones that exist and contains files or folders.
2. **Restarting a job** - When restarting a job, all folders that are defined in folder paths and exist, will be moved from its current location to a subfolder called "RESTARTED". This is to be able to be sure that the job is completely restarted, and no old files remain in the file structure. The RESTARTED folder will have to be emptied manually. **Tha folder paths must be valid DFile Paths**

**Example** - Defines a processing, packaging and store location for a job
```json
{
    "folder_paths": [
        "PROCESSING:/%{job_id}",
        "PACKAGING:/%{package_name}",
        "STORE:/%{package_name}"
    ]
}
```

### Flow steps
The flow steps define the core of the workflow, as nothing would be done without them. Each step has the following options:
**step** (Integer) - The step identifier, must be a number.
**process** (Process - Available values are defined in [Processes] (#processes)) - The name of the process to be run for this step. The process has to be predefined.
**goto_true** (Integer - Another existing step identifier) - Points to which step should be run when this step is finished.
**condition** (Evaluable statement) (Not mandatory) - A condition which has to return **true** for the step to execute, otherwise the step will finish and the next one be started. Example of a condition is "'%{copyright}' == 'true'".
**params** - The parameters available for the given **process**, see documentation on each process.

**Example 1:** A manual flow step which should only run if job is copyrighted, and starts step nr **30** when done:
```json
  {
    "step": 20,
    "process": "CONFIRMATION",
    "description": "Check with copyright owners",
    "condition": "'%{copyright}' == 'true'",
    "goto_true": 30,
    "params": {
      "start": true,
      "manual": true,
      "msg": "Copyright is cleared!"
    }
  }
```
## Processes
A process is a potiential step which can be used in a workflow. These processes can be triggered manually & via API-request, or through the built in Queue Manager.
### Using variables
Variables can be used within FlowStep parameters to be able to access a job's properties, such as its ID, PackageName or PageCount. It can also be used to access flow-specific parameters.

*To access a variable, use the following syntax:*
```
%{variable_name}
```
*When using the variable 'job_id' within a parameter, it could look like this:*
```
..
source_folder_path: PROCESSING:/%{job_id}
..
```
*When accessing a flow-parameter, the name of the variable is the same as the name of the parameter. Let's say the parameter 'processing_station' is defined, it could be used as follows:*
```
..
source_folder_path: %{processing_station}:/%{job_id}
..
```

#### Predefined variables
Variables are predefined in the code [app/model/flow_step.rb#substitute_parameters] (https://github.com/ub-digit/dFlow/blob/master/app/models/flow_step.rb#L273-L285). This is where new variables should be added if needed.

**job_id** : The job's ID.
**page_count** : The number of pages(images) of the job. Typically assigned using process COLLECT_JOB_METADATA.
**package_name** : The package name of the job, using the ID and a formatting string defined in the configuration file. For example, format 'GUB%07d' for job id '123' gives package name 'GUB0000123'.
**copyright** : Returns a boolean string value of copyright, i.e. 'true' (copyrighted) or 'false' (not copyrighted).
**copyright_protected** : Same as "copyright", but is easier to understand when used in a condition.
**chron_1, chron_2, chron_3** : Returns the metadata values for chronology. Generally used for periodicals.
**ordinality_1, ordinality_2, ordinality_3** : Returns the metadata values for ordinality. Generally used for periodicals.
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
    "params": {
      "manual": false
    }
  },
```
*****
#### QUALITY_CONTROL
##### Description
Displays a link to a PDF file, which is meant to be checked for quality deficiencies.
##### Parameters
**pdf_file_path** (Path) - Path to a previously generated PDF file to be quality checked.
**manual** (true / false) - Should be set to **true** to get a confirmation button.
**msg** (String, e.g. "Operation done!")
##### Expected outcome
This process only finishes the current flow step.
##### Examples
**Example 1:** The manual task of reviewing a pdf file needs a place in the workflow. When done, the user klicks a confirmation button in DFlow to move the workflow to the next step in the process.
```json
{
    "step": 60,
    "process": "QUALITY_CONTROL",
    "description": "Check quality of PDF file",
    "goto_true": 70,
    "params": {
      "pdf_file_path": "PROCESSING:/%{job_id}/pdf/%{job_id}.pdf",
      "manual": true,
      "msg": "Quality control done!"
    }
  },
```
*****
#### ASSIGN_METADATA
##### Description
Displays thumbnails for a given path of images, and lets the user assign physical and logical metadata per image.
##### Parameters
**images_folder_path** (Path) - Path to the **job root folder** where images can be found. A **thumbnails** folder will be created under this directory.
**source** (Relative folder path) - The relative folder path from **images_folder_path**, e.g. 'web' if the files are located in <job_folder>/web, and 'web/jpg' if the files are located in <job_folder>/web/jpg.
**filetype** (Filetype, e.g. 'jpg, tif') - Filetype of files in source folder.
**save** (true / false) - Should be set to **true**, means that the operation will save the job as well as move to the next flow step.
**manual** (true / false) - Should be set to **true** to get a confirmation button.
**msg** (String, e.g. "Metadata done!")
##### Expected outcome
This process finishes the current flow step, **and** saves the job including the set metadata!.
##### Examples
**Example 1:** The task of assigning metadata needs a place in the flow. When done, the user klicks a confirmation button in DFlow to move the workflow to the next step in the process, as well as save the metadata.
```json
{
    "step": 60,
    "process": "ASSIGN_METADATA",
    "description": "Assign metadata per image",
    "goto_true": 80,
    "params": {
        "manual": true,
        "images_folder_path": "PROCESSING:/%{job_id}",
        "source": "web",
        "save": true,
        "msg": "Metadata done!",
        "filetype": "jpg"
    }
  },
```
*****
#### ASSIGN_FLOW_PARAMETERS
##### Description
Displays a form with the available parameters in the current flow.
##### Parameters
**save** (true / false) - Should be set to **true**, means that the operation will save the job as well as move to the next flow step.
**manual** (true / false) - Should be set to **true** to get a confirmation button.
**msg** (String, e.g. "Assign done!")
##### Expected outcome
This process finishes the current flow step, **and** saves the job including the new parameters!.
##### Examples
**Example 1:** The task of assigning flow parameters needs a place in the flow. When done, the user klicks a confirmation button in DFlow to move the workflow to the next step in the process, as well as save the new flow parameters.
```json
{
    "step": 60,
    "process": "ASSIGN_FLOW_PARAMETERS",
    "description": "Assign or change flow parameters",
    "goto_true": 80,
    "params": {
        "manual": true,
        "save": true,
        "msg": "Assign done!"
    }
  },
```
### Waiting processes
A *waiting process* works much like a triggered process, in that it's only function is to finish the current flow step and move to the next one. The trigger in this case however, is its **condition**, which can consist of waiting for a **specific file to exist** or a **specific number of files** to exist, for example.
Waiting processes are run by the internal Queue Manager, and shares queue with all other waiting processes in it.
*****
#### WAIT_FOR_FILE
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
    "params": {
      "file_path": "PROCESSING:/%{job_id}/xml/file1.xml"
    }
  },
```
*****
#### WAIT_FOR_FILES
##### Description
Waits until given folder contains the given amount of files of a given type before finishing.
##### Parameters
**folder_path** (Path) - Path of directory in which to look for files
**filetype** (File extension, e.g. tif, jpg, xml) - Extension of files to look for
**count** (Number) - Number of files to look for
##### Expected outcome
The process keeps repeating until the given number of files are found. If more files than expected
are found, the job is put into quarantine.
##### Examples
**Example 1:** An external process creates jpg files, and the workflow must wait until all files are created before proceeding.
*****
```json
{
    "step": 60,
    "process": "WAITFOR_FILES",
    "description": "Check if all jpg files have been created",
    "goto_true": 70,
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
**format_string** (Format string, e.g. '%04d' for 0001.jpg) (Not mandatory) - Tells new format of file names after being copied, can be omitted if filenames should remain the same.
**filetype** (Filetype, e.g. 'tif', 'jpg' et.c.) (Not mandatory) - If given, only copies files with the given filetype. Files will only be copied from the source folder, **subdirectories or nested files will NOT be copied**.
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
    "params": {
      "source_folder_path": "MACHINE1:/scans/%{job_id}/tif",
      "destination_folder_path": "PROCESSING:/%{job_id}/tif",
      "format_string": "%04d",
      "filetype": "tif"
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
**format_string** (Format string, e.g. '%04d' for 0001.jpg) (Not mandatory) - Tells new format of file names after being copied, can be omitted if filenames should remain the same.
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
    "params": {
      "source_file_path": "MACHINE1:/scans/%{job_id}/tif",
      "destination_file_path": "PROCESSING:/%{job_id}/tif",
      "format_string": "%04d",
      "filetype": "tif"
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
    "params": {
      "job_parent_path": "PROCESSING:/"
    }
  },
```
*****
#### COLLECT_JOB_METADATA
##### Description
Collects metadata from a given file folder, storing file names and file count as metadata for the job in DFlow. Zero files in the folder is considered an error and will put the job into quarantine.
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
**format_string** (String, ImageMagick convert parameter string) - A valid ImageMagick parameter string for the **convert** command, saying which arguments should apply to the new format.
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
    "params": {
        "source_folder_path": "PROCESSING:/%{job_id}/mst/tif_lzw",
         "destination_folder_path": "PROCESSING:/%{job_id}/web/jpg",
         "to_filetype": "jpg",
         "format_string": "-unsharp 0.3x0.5+4.0+0 -level 10%,93% -quality 94"
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
**checksum** (true/false) (not mandatory) - Default: false. If true, perform SHA-512 checksum on each file and include in METS file.
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
    "params": {
      "gupea_collection": "2077/38764",
      "pdf_file_path": "STORE:/%{package_name}/pdf/%{package_name}.pdf",
      "gupea_folder_path": "GUPEA:/%{job_id}"
    }
  },
```
*****
#### COMBINE_PDF_FILES
##### Description
Combines a number of PDF-files into a single PDF.
##### Parameters
**source_folder_path** (Path) - Path of folder containing PDF-files to be combined.
**destination_file_path** (Path) - Path of resulting pdf file, including file name.
##### Expected outcome
A PDF-file is created at the location specified from the source documents.
##### Examples
**Example 1:** A PDF file should be created from a folder of single files, named after the job's ID.
```json
{
        "step": 150,
        "process": "COMBINE_PDF_FILES",
        "description": "Combine PDF files to one single file",
        "goto_true": 155,
        "params": {
          "source_folder_path": "PROCESSING:/%{job_id}/pdf_single",
          "destination_file_path": "PROCESSING:/%{job_id}/pdf/%{job_id}.pdf"
        }
      },
```
*****
#### CREATE_LIBRIS_ITEM
##### Description
Creates an electronic item and a holding item in Libris.
##### Parameters
**libris_id** (Integer) - Identifier of the print item in Libris, used as original.
**sigel** (String) (not mandatory) - Sigel of the digitizing library, used in marc field 040a.
**url** (String) - Link to the electronic resource.
**type** (String) (not mandatory) - Reproduction type, used in field 533 a. E.g. *Digitalt faksimil och elektronisk text.*
**place** (String) (not mandatory) - Reproduction place, used in field 533 b. E.g. *Göteborg : *
**agency** (String) (not mandatory) - Reproduction agency, used in field 533 c. E.g. *Göteborgs universitetsbibliotek,*
**bibliographic_code** (String) (not mandatory) - Additional bibliographic code, used in 042 subfield 9.
**create_holding** (true / false) (not mandatory) - If true, a holding item will be created.
**publicnote** (String) (not mandatory) - Public note, used in field 856 z.
**remark** (String) (not mandatory) - Remark, used in field 856 x.
**publicnote_holding** (String) (not mandatory) - Public note in holding item, used in field 852 z.
**remark_holding** (String) (not mandatory) - Remark in holding item, used in field 852 x.
##### Expected outcome
An electronic item is created in Libris
##### Examples
**Example:** A PDF file should be created from a folder of single files, named after the job's ID.
```json
{
        "step": 150,
        "process": "CREATE_LIBRIS_ITEM",
        "description": "Creates electronic item in Libris",
        "goto_true": 155,
        "params": {
          "libris_id": "%{catalog_id}",
          "url": "%{gupea_url}"
        }
      },
```