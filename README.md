# DFlow

DFlow is a Ruby-On-Rails Application, built to support workflows for large digitizing projects.

## Table of Contents

* [Processes] (#processes)

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

### Triggered flow steps

#### CONFIRMATION
##### Description 
This flow step is meant to be used as a confirmation trigger that the current step is completed. The trigger can either be called by a manual press of a button inside DFlow, or through an API-request form an external service.
##### Parameters
**manual** (true / false) (not mandatory) - If true, a confirmation button will be visible inside DFlow.
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
