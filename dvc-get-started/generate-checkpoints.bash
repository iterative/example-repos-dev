#!/bin/bash
# See https://dvc.org/doc/start

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.
set -eux

git checkout base
git checkout -b checkpoints

mkdir data
dvc import https://github.com/iterative/dataset-registry \
           mnist/raw -o data/raw
git add data/raw.dvc data/.gitignore
git commit -m "Add raw MNIST data"
git tag -a "cp-1-track-data" -m "Data file added."

dvc push

# We'll use the main code and modify the parts of it

cp -r ${HERE}/code-cp-2-basic/* ${REPO_PATH}/
pip install -r ${REPO_PATH}/requirements.txt
git add .
git commit -m "Added 'checkpoint: true' to the params file"
git tag -a "cp-2-basic" -m "checkpoint: true example"

cp -r ${HERE}/code-cp-3-signal-file/* ${REPO_PATH}/
git add .
git commit -m "Modified train.py for signal files"
git tag -a "cp-3-signal-file" -m "Checkpoints: Signal file example"

cp -r ${HERE}/code-cp-4-python-api/* ${REPO_PATH}/
git add .
git commit -m "Using make_checkpoint() in the callback"
git tag -a "cp-4-python-api" -m "Checkpoints: Python API example"


cp -r ${HERE}/code-cp-5-dvclive/* ${REPO_PATH}/
git add .
git commit -m "DVClive modifications"
git tag -a "cp-5-dvclive" -m "Checkpoints: DVClive stage added"

