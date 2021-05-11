#!/bin/bash
# See https://dvc.org/doc/start

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.

set -eux

git init
git checkout -b main
cp $HERE/code-main/README.md .
git add .
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m  "Initialize Git repository"
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "git-init" -m "Git initialized."


dvc init
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Initialize DVC project"
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "dvc-init" -m "DVC initialized."

# Remote active on this env only, for writing to HTTP redirect below.
dvc remote add -d --local storage s3://dvc-public/remote/get-started
# Actual remote for generated project (read-only). Redirect of S3 bucket above.
dvc remote add -d storage https://remote.dvc.org/get-started
git add .
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Configure default remote"
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "config-remote" -m "Read-only remote storage configured."

test -d data || mkdir data

dvc import https://github.com/iterative/dataset-registry \
           mnist/raw -o data/raw

git add data/raw.dvc data/.gitignore
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Add raw MNIST data"
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "import-mnist-data" -m "MNIST data file added."
dvc push

cp -r ${HERE}/code-main/src .
cp ${HERE}/code-main/requirements.txt .
cp ${HERE}/code-main/params.yaml .
pip install -r ${REPO_PATH}/requirements.txt
git add .
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Add source code files to repo"
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "source-code" -m "Source code added."

dvc stage add -n prepare \
              -p prepare.seed \
              -p prepare.remix \
              -p prepare.remix_split \
              -d data/raw/ \
              -d src/prepare.py \
              -o data/prepared \
              python3 src/prepare.py

dvc repro prepare 

git add data/.gitignore dvc.yaml dvc.lock
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Create data preparation stage"
dvc push
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "prepare" -m "First pipeline stage (data preparation) created."

dvc stage add -n preprocess \
    -p preprocess.seed \
    -p preprocess.normalize \
    -p preprocess.shuffle \
    -p preprocess.add_noise \
    -p preprocess.noise_amount \
    -p preprocess.noise_s_vs_p \
    -d data/prepared/ \
    -d src/preprocess.py \
    -o data/preprocessed/ \
    python3 src/preprocess.py

dvc repro preprocess
dvc push
git add data/.gitignore dvc.yaml dvc.lock
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Second pipeline stage (preprocessing) created"
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "preprocess" -m "Second pipeline stage (data preprocessing) created."

mkdir models
dvc stage add -n train \
              -p train.seed \
              -p train.validation_split \
              -p train.epochs \
              -p train.batch_size \
              -p model.name \
              -p model.optimizer \
              -p model.mlp.units \
              -p model.mlp.activation \
              -p model.cnn.dense_units \
              -p model.cnn.conv_kernel_size \
              -p model.cnn.conv_units \
              -p model.cnn.dropout \
              -d src/train.py \
              -d src/models.py \
              -d data/preprocessed/ \
              -o models/model.h5 \
              --plots-no-cache logs.csv \
              python3 src/train.py

# TODO: We may need to add some `dvc plots modify` commands here!

dvc repro train
git add .gitignore dvc.yaml dvc.lock models/.gitignore
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Created training stage"
dvc push
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "training" -m "Training stage created."

dvc stage add -n evaluate \
              -d src/evaluate.py \
              -d models/model.h5 \
              -M metrics.json \
              python3 src/evaluate.py
dvc repro evaluate

git add .gitignore dvc.yaml dvc.lock metrics.json
TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git commit -m "Create evaluation stage"
dvc push
GIT_AUTHOR_DATE=${TAG_TIME} \
GIT_COMMITTER_DATE=${TAG_TIME} \
git tag -a "evaluation" -m "Evaluation stage created."

