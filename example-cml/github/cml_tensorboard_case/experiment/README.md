# CML with Tensorboard use case

This repository contains a sample project using [CML](https://github.com/iterative/cml) with Tensorboard.dev to track model training in real-time. When a pull request is made, the following steps occur:
- GitHub will deploy a runner machine with a specified CML Docker environment
- A Tensorboard.dev page will be created 
- CML will report a link to the Tensorboard as a comment in the pull request
- The runner will execute a workflow to train a ML model (`python train.py`)

The key file enabling these actions is `.github/workflows/cml.yaml`.

## Secrets and environmental variables
In this example, `.github/workflows/cml.yaml` contains two environmental variables that are stored as repository secrets.

| Secret  | Description  | 
|---|---|
|  GITHUB_TOKEN | This is set by default in every GitHub repository. It does not need to be manually added.  |
| TB_CREDENTIALS  | Tensorboard credentials | 

To access your Tensorboard credentials:
1. On your local machine, run `tensorboard dev upload` 
2. Accept the TOS and follow the authentication procedure. 
3. When you have authenticated, copy your credentials out of `~/.config/tensorboard/credentials/uploader-creds.json` (this is the typical path for OSX/Linux systems). Paste these credentials as the secret TB_CREDENTIALS. 


## Cloning this project
Note that if you clone this project, you will have to configure your own TB credentials for the example. 

