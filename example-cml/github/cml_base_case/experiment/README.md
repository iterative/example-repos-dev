# CML basic use case

This repository contains a sample project using [CML](https://github.com/iterative/cml). When a pull request is made in this repository, the following will occur:
- GitHub will deploy a runner machine with a specified CML Docker environment
- The runner will execute a workflow to train a ML model (`python train.py`)
- A visual CML report about the model performance will be returned as a comment in the pull request

The key file enabling these actions is `.github/workflows/cml.yaml`.

## Secrets and environmental variables
The only environmental variable set in `.github/workflows/cml.yaml` is `GITHUB_TOKEN`, which is configured by default in every GitHub repository. No secrets must be set by the user. 

