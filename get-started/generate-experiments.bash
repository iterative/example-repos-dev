#!/usr/bin/env bash

set -veux

export REPO_PATH="${REPO_ROOT}"/experiments

mkdir -p "$REPO_PATH"
pushd "${REPO_PATH}"

virtualenv -p python3 .venv
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .venv/bin/activate
echo '.venv/' > .gitignore
pip install 'dvc[all]'

git init
git checkout -b main
cp $HERE/code-experiments/README.md "${REPO_PATH}" 
cp $HERE/code-experiments/.gitignore "${REPO_PATH}"
dvc init
# Remote active on this env only, for writing to HTTP redirect below.
dvc remote add -d --local storage s3://dvc-public/remote/get-started
# Actual remote for generated project (read-only). Redirect of S3 bucket above.
dvc remote add -d storage https://remote.dvc.org/get-started
tag_tick
git add .
git commit -m "Initialized DVC and Configured Remote"
git tag -a "init" -m "Initialized DVC and Remote"

test -d data/fashion-mnist || mkdir -p data/fashion-mnist

dvc import https://github.com/iterative/dataset-registry \
           fashion-mnist/raw -o data/fashion-mnist/raw

tag_tick
git add data/fashion-mnist/raw.dvc data/fashion-mnist/.gitignore
git commit -m "Add Fashion-MNIST data"
git tag -a "data" -m "Fashion-MNIST data file added."
dvc push

cp -r "${HERE}"/code-experiments/src .
cp "${HERE}"/code-experiments/requirements.txt .
cp "${HERE}"/code-experiments/params.yaml .
pip install -r "${REPO_PATH}"/requirements.txt

tag_tick
git add .
git commit -m "Add source code for the experiments"
git tag -a "source-code" -m "Source code for experiments added."

cp "${HERE}"/code-experiments/dvc.yaml .
tag_tick
git add dvc.yaml 
git commit -m "Added experiments pipeline"
git tag -a "pipeline" -m "Experiments pipeline added."

dvc exp run
tag_tick
git add data/fashion-mnist/.gitignore models/fashion-mnist/.gitignore dvc.lock logs.csv metrics.json 
git commit -m "Baseline experiment run"
git tag -a "baseline" -m "Baseline experiment"

popd 
unset REPO_PATH