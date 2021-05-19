#!/bin/bash

set -veux

export REPO_PATH="${REPO_ROOT}"/checkpoints

mkdir -p "$REPO_PATH"
pushd "${REPO_PATH}"

virtualenv -p python3 .venv
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .venv/bin/activate
echo '.venv/' > .gitignore

pip install 'dvc[all]'

git init
git checkout -b main

cp -r "${HERE}"/code-checkpoints/00-common/* "${REPO_PATH}"/
tag_tick
git add "${REPO_PATH}/"*
git commit -m "Added common files for checkpoints"
git tag -a "checkpoints-base" -m "checkpoints baseline"

# We'll use the main code and modify the parts of it

cp -r "${HERE}"/code-checkpoints/00-common/* "${REPO_PATH}"/
cp -r "${HERE}"/code-checkpoints/basic/* "${REPO_PATH}"/
pip install -r "${REPO_PATH}"/requirements.txt

tag_tick
git add .
git commit -m "Added 'checkpoint: true' to the params file"
git tag -a "basic" -m "checkpoint: true example"


cp -r "${HERE}"/code-checkpoints/00-common/* "${REPO_PATH}"/
cp -r "${HERE}"/code-checkpoints/signal-file/* "${REPO_PATH}"/

tag_tick
git add .
git commit -m "Modified train.py for signal files"
git tag -a "signal-file" -m "Checkpoints: Signal file example"


cp -r "${HERE}"/code-checkpoints/00-common/* "${REPO_PATH}"/
cp -r "${HERE}"/code-checkpoints/python-api/* "${REPO_PATH}"/
tag_tick
git add .
git commit -m "Using make_checkpoint() in the callback"
git tag -a "python-api" -m "Checkpoints: Python API example"


cp -r "${HERE}"/code-checkpoints/00-common/* "${REPO_PATH}"/
cp -r "${HERE}"/code-checkpoints/dvclive/* "${REPO_PATH}"/

tag_tick
git add .
git commit -m "DVClive modifications"
git tag -a "dvclive" -m "Checkpoints: DVClive stage added"

popd

unset REPO_PATH