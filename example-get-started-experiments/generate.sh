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

TOTAL_TAGS=8
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
pip install "git+https://github.com/iterative/dvc#egg=dvc[s3]" gto

git init
cp $HERE/code/README.md .
cp $HERE/code/.devcontainer.json .
cp $HERE/code/.gitattributes .
cp $HERE/code/.gitlab-ci.yml .
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

pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu118
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
cp -r $HERE/code/sagemaker .
cp $HERE/code/params.yaml .
sed -e "s/base_lr: 0.01/base_lr: $BEST_EXP_BASE_LR/" -i".bkp" params.yaml
rm params.yaml.bkp

git rm -r --cached 'results'
git commit -m "stop tracking results"

dvc stage add -n data_split \
  -p base,data_split \
  -d src/data_split.py -d data/pool_data \
  -o data/train_data -o  data/test_data \
  python src/data_split.py

dvc remove models/model.pkl.dvc
dvc stage add -n train \
  -p base,train \
  -d src/train.py -d data/train_data \
  -o models/model.pkl -o models/model.pth \
  -o results/train python src/train.py

dvc stage add -n evaluate \
  -p base,evaluate \
  -d src/evaluate.py -d models/model.pkl -d data/test_data \
  -o results/evaluate python src/evaluate.py

dvc stage add -n sagemaker \
  -d models/model.pth -o model.tar.gz \
  'cp models/model.pth sagemaker/code/model.pth && cd sagemaker && tar -cpzf model.tar.gz code/ && cd .. && mv sagemaker/model.tar.gz .  && rm sagemaker/code/model.pth'

git add .
tick
git commit -m "Convert Notebook to dvc.yaml pipeline"


dvc exp run
git add .
tick
git commit -m "Run dvc.yaml pipeline"
git tag -a "2-dvc-pipeline" -m "Experiment using dvc pipeline"
gto register pool-segmentation --version v1.0.0
gto assign pool-segmentation --version v1.0.0 --stage dev

export GIT_AUTHOR_NAME="David de la Iglesia"
export GIT_AUTHOR_EMAIL="daviddelaiglesiacastro@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

dvc exp run --queue --set-param 'train.arch=alexnet,resnet34,squeezenet1_1' --message 'Tune train.arch'
dvc exp run --run-all

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
