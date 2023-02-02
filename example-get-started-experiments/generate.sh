#!/bin/bash

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.
set -eux
HERE="$( cd "$(dirname "$0")" ; pwd -P )"
REPO_NAME="example-get-started-experiments"
REPO_PATH="$HERE/build/$REPO_NAME"
PROD=${1:-false}

if [ -d "$REPO_PATH" ]; then
  echo "Repo $REPO_PATH already exists, please remove it first."
  exit 1
fi

TOTAL_TAGS=3
STEP_TIME=100000
BEGIN_TIME=$(( $(date +%s) - ( ${TOTAL_TAGS} * ${STEP_TIME}) ))
export TAG_TIME=${BEGIN_TIME}
export GIT_AUTHOR_DATE="${TAG_TIME} +0000"
export GIT_COMMITTER_DATE="${TAG_TIME} +0000"
tick(){
  export TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
  export GIT_AUTHOR_DATE="${TAG_TIME} +0000"
  export GIT_COMMITTER_DATE="${TAG_TIME} +0000"
}

export GIT_AUTHOR_NAME="Alex Kim"
export GIT_AUTHOR_EMAIL="alex000kim@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

mkdir -p $REPO_PATH
pushd $REPO_PATH

virtualenv -p python3 .venv
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .venv/bin/activate
echo '.venv/' > .gitignore

# Installing from main since we'd like to update repo before
# the release
pip install "git+https://github.com/iterative/dvc#egg=dvc[s3]"

git init
cp $HERE/code/README.md .
cp $HERE/code/.devcontainer.json .
cp $HERE/code/.gitattributes .
cp $HERE/code/requirements.txt .
cp -r $HERE/code/.github .
git add .
tick
git commit -m "Initialize Git repository"
git branch -M main


dvc init
# Remote active on this env only, for writing to HTTP redirect below.
dvc remote add -d --local storage s3://dvc-public/remote/get-started-pools
# Actual remote for generated project (read-only). Redirect of S3 bucket above.
dvc remote add -d storage https://remote.dvc.org/get-started-pools
git add .
tick
git commit -m "Initialize DVC project"


cp -r $HERE/code/data .
git add data/.gitignore data/pool_data.dvc
tick
git commit -m "Add data"
dvc pull


cp -r $HERE/code/notebooks .
git add .
git commit -m "Add notebook using DVCLive"

pip install -r requirements.txt
pip install jupyter
jupyter nbconvert --execute 'notebooks/TrainSegModel.ipynb' --inplace
# Apply best experiment
BEST_EXP_ROW=$(dvc exp show --drop '.*' --keep 'Experiment|evaluate/dice_multi|base_lr' --csv --sort-by evaluate/dice_multi | tail -n 1)
BEST_EXP_NAME=$(echo $BEST_EXP_ROW | cut -d, -f 1)
BEST_EXP_BASE_LR=$(echo $BEST_EXP_ROW | cut -d, -f 3)
dvc exp apply $BEST_EXP_NAME
git add .
tick
git commit -m "Run notebook and apply best experiment"
git tag -a "1-notebook-dvclive" -m "Experiment using Notebook"


cp -r $HERE/code/src .
cp $HERE/code/params.yaml .
sed -e "s/base_lr: 0.01/base_lr: $BEST_EXP_BASE_LR/" -i".bkp" params.yaml
rm params.yaml.bkp

dvc stage add -n data_split \
  -p base,data_split \
  -d src/data_split.py -d data/pool_data \
  -o data/train_data -o  data/test_data \
  python src/data_split.py

dvc stage add -n train \
  -p base,train \
  -d src/train.py -d data/train_data \
  -o models/model.pkl \
  -M results/train/metrics.json \
  --plots-no-cache results/train/plots \
  python src/train.py

dvc stage add -n evaluate \
  -p base,evaluate \
  -d src/evaluate.py -d models/model.pkl -d data/test_data \
  -M results/evaluate/metrics.json \
  --plots-no-cache results/evaluate/plots \
  python src/evaluate.py
git add .
tick
git commit -m "Convert Notebook to dvc.yaml pipeline"


dvc exp run
git add .
tick
git commit -m "Run dvc.yaml pipeline"
git tag -a "2-dvc-pipeline" -m "Experiment using dvc pipeline"

export GIT_AUTHOR_NAME="David de la Iglesia"
export GIT_AUTHOR_EMAIL="daviddelaiglesiacastro@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

git checkout -b "tune-architecture"

unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_DATE

dvc exp run --queue --set-param 'train.arch=alexnet,resnet34,squeezenet1_1'

dvc exp run --run-all
# Apply best experiment
EXP=$(dvc exp show --csv --sort-by results/evaluate/metrics.json:dice_multi | tail -n 1 | cut -d , -f 1)
dvc exp apply $EXP
tick
git commit -am "Run experiments tuning architecture. Apply best one"

git checkout main

dvc push -A

popd

unset TAG_TIME
unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_DATE
unset GIT_AUTHOR_NAME
unset GIT_AUTHOR_EMAIL
unset GIT_COMMITTER_NAME
unset GIT_COMMITTER_EMAIL

cat README.md
