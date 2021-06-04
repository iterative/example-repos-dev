#!/usr/bin/env bash

set -veux

add_main_pipeline() {
    dvc stage add -n prepare \
                  -d src/prepare.py \
                  -d data/fashion-mnist/raw/ \
                  -p prepare.remix \
                  -p prepare.remix_split \
                  -p prepare.seed \
                  --outs-no-cache data/fashion-mnist/prepared \
                  python3 src/prepare.py

    echo "prepared/" >> data/fashion-mnist/.gitignore

    dvc stage add -n preprocess \
                  -d data/fashion-mnist/prepared/ \
                  -d src/preprocess.py \
                  --outs-no-cache data/fashion-mnist/preprocessed \
                  python3 src/preprocess.py
    echo "preprocessed/" >> data/fashion-mnist/.gitignore

    dvc stage add -n train \
                -d data/fashion-mnist/preprocessed/ \
                -d src/models.py \
                -d src/train.py \
                -p model.cnn.conv_kernel_size \
                -p model.cnn.conv_units \
                -p model.cnn.dense_units \
                -p model.cnn.dropout \
                -p model.mlp.activation \
                -p model.mlp.units \
                -p model.name \
                -p model.optimizer \
                -p train.batch_size \
                -p train.epochs \
                -p train.seed \
                -p train.validation_split \
                --outs-no-cache models/fashion-mnist/model.h5 \
                --plots-no-cache logs.csv \
                python3 src/train.py

    dvc stage add -n evaluate \
                  -d models/fashion-mnist/model.h5 \
                  -d src/evaluate.py \
                  --metrics-no-cache metrics.json \
                  python3 src/evaluate.py 

}

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

tag_tick
add_main_pipeline
git add dvc.yaml 
git commit -m "Added experiments pipeline"
git tag -a "pipeline" -m "Experiments pipeline added."

dvc exp run
tag_tick
echo "model.h5" >> models/fashion-mnist/.gitignore
git add models/fashion-mnist/.gitignore data/fashion-mnist/.gitignore dvc.lock logs.csv metrics.json 
git commit -m "Baseline experiment run"
git tag -a "baseline" -m "Baseline experiment"

git status 

popd 
unset REPO_PATH
