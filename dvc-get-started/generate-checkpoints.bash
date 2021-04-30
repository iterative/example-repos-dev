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
git commit -m "Added checkpoint: true to the params file"
git tag -a "cp-2-basic" -m "checkpoint: true example"

git add data/.gitignore dvc.yaml dvc.lock
git commit -m "Create data preparation stage"
dvc push
git tag -a "cp-3-signal-file" -m "Checkpoints: Signal file example"

git add data/.gitignore dvc.yaml dvc.lock
git tag -a "cp-4-python-api" -m "Checkpoints: Python API example"
git tag -a "cp-5-dvclive" -m "Checkpoints: DVClive stage added"

