#!/bin/bash
# See https://dvc.org/doc/start

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.
set -eux

git checkout evaluation
git checkout -b checkpoints

git tag -a "checkpoints-base" -m "checkpoints baseline"

# We'll use the main code and modify the parts of it

cp -r ${HERE}/code-checkpoints/basic/* ${REPO_PATH}/
pip install -r ${REPO_PATH}/requirements.txt
git add .
git commit -m "Added 'checkpoint: true' to the params file"
git tag -a "basic" -m "checkpoint: true example"


cp -r ${HERE}/code-checkpoints/signal-file/* ${REPO_PATH}/
git add .
git commit -m "Modified train.py for signal files"
git tag -a "signal-file" -m "Checkpoints: Signal file example"


cp -r ${HERE}/code-checkpoints/python-api/* ${REPO_PATH}/
git add .
git commit -m "Using make_checkpoint() in the callback"
git tag -a "python-api" -m "Checkpoints: Python API example"


cp -r ${HERE}/code-checkpoints/dvclive/* ${REPO_PATH}/
git add .
git commit -m "DVClive modifications"
git tag -a "dvclive" -m "Checkpoints: DVClive stage added"

