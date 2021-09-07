#!/bin/bash

set -eu

if [ "$#" -ne 5 ]; then
    echo "\n\nERROR: 
    You must provide the following arguments:
    1. Git account or org name (eg, tapadipti)
    2. Repo name (eg, fashion_mnist)
    3. Git author name (eg, tapadipti)
    4. Git author email (eg, tapadipti@gmail.com)
    5. DVC remote URL (eg, s3://mydvc/tapa)
    Eg, sh generator.sh tapadipti fashion_mnist tapadipti tapadipti@gmail.com s3://mydvc/tapa
    The repo will be created at https://github.com/GIT_ACC_OR_ORG/REPO_NAME (eg, https://github.com/tapadipti/fashion_mnist).
    If this repo already exists, it will be replaced by the new one - so make sure that you don't need the existing one.
    Make sure you have the required access to the Git account and DVC remote location.\n\n"
    exit
fi

GIT_ORG=$1
REPO_NAME=$2
GIT_AUTHOR_NAME=$3
GIT_AUTHOR_EMAIL=$4
DVC_REMOTE=$5

echo $DVC_REMOTE

HERE="$( cd "$(dirname "$0")" ; pwd -P )"
REPO_PATH="$HERE/build/$REPO_NAME"

if [ -d "$REPO_PATH" ]; then
  echo "Repo $REPO_PATH already exists, please remove it first."
  exit 1
fi

TOTAL_TAGS=15
STEP_TIME=100000
BEGIN_TIME=$(( $(date +%s) - ( ${TOTAL_TAGS} * ${STEP_TIME}) ))
export TAG_TIME=${BEGIN_TIME}
export GIT_AUTHOR_DATE=${TAG_TIME}
export GIT_COMMITTER_DATE=${TAG_TIME}
tick(){
  export TAG_TIME=$(( ${TAG_TIME} + ${STEP_TIME} ))
  export GIT_AUTHOR_DATE=${TAG_TIME}
  export GIT_COMMITTER_DATE=${TAG_TIME}
}

export GIT_AUTHOR_NAME="$GIT_AUTHOR_NAME"
export GIT_AUTHOR_EMAIL="$GIT_AUTHOR_EMAIL"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

mkdir -p $REPO_PATH
pushd $REPO_PATH

virtualenv -p python3 .venv
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .venv/bin/activate
echo '.venv/' > .gitignore

pip install gitpython
pip install "git+https://github.com/iterative/dvc#egg=dvc[all]"

git init
cp $HERE/code/README.md .
cp $HERE/code/samples.png .
git add .
tick
git commit -m "Initialize Git repository"
git tag -a "0-git-init" -m "Git initialized."

dvc init
tick
git commit -m "Initialize DVC project"
git tag -a "1-dvc-init" -m "DVC initialized."

dvc remote add -d storage $DVC_REMOTE
git add .
tick
git commit -m "Configure default remote"
git tag -a "2-config-remote" -m "Remote storage configured."
dvc push

mkdir src
cp ../../code/load_data.py src/load_data.py
cp ../../code/train_NN.py src/train.py
cp ../../code/evaluate_NN.py src/evaluate.py
cp ../../code/params.yaml params.yaml
cp ../../code/requirements.txt requirements.txt
pip install -r requirements.txt
mkdir output
git add .
tick
git commit -m "Created a neural network to solve the problem"
git tag -a "3-neural-net" -m "Neural network created."

pip install -r ../../code/requirements.txt
dvc run -n load_data -d src/load_data.py -o output/data.pkl python src/load_data.py
git add .
tick
git commit -m "Create load data stage"
git tag -a "4-load-data-stage" -m "First pipeline stage (data loading) created."
dvc push

dvc run -n train -p train.batch_size,train.hidden_units,train.dropout,train.num_epochs,train.lr -d src/train.py -d output/data.pkl -o output/model.h5 --plots-no-cache output/train_logs.csv python src/train.py
git add .
tick
git commit -m "Create train stage"
git tag -a "5-train-stage" -m "Second pipeline stage (train) created."
dvc push

dvc run -n evaluate -d src/evaluate.py -d output/data.pkl -d output/model.h5 -M output/metrics.json --plots-no-cache output/predictions.json python src/evaluate.py
dvc plots modify output/predictions.json --template confusion -x actual -y predicted
dvc plots modify output/train_logs.csv --template linear -x epoch -y accuracy
git add .
tick
git commit -m "Create evaluate stage"
git tag -a "baseline-nn-experiment" -m "Baseline (neural net) experiment evaluation"
git tag -a "6-nn-evaluation" -m "Baseline (neural net) evaluation stage created."
dvc push

cp ../../code/train_CNN.py src/train.py
cp ../../code/evaluate_CNN.py src/evaluate.py
git add .
tick
git commit -m "Build CNN"
git tag -a "7-cnn" -m "CNN created."

dvc repro
git add .
tick
git commit -m "Evaluate CNN"
git tag -a "8-cnn-evaluation" -m "CNN evaluated."
dvc push

sed -e "s/lr: 0.01/lr: 0.001/" -i "" params.yaml
dvc repro train
git add .
tick
git commit -am "Reproduce model using learning rate = 0.0001"
git tag -a "9-lower-lr" -m "Model retrained using lr = 0.0001."

dvc repro evaluate
git add .
tick
git commit -am "Evaluate model with lower lr"
git tag -a "low-lr-experiment" -m "Low lr experiment evaluation"
git tag -a "10-low-lr-experiment" -m "Evaluated low lr model."
dvc push

sed -e "s/dropout: 0.40/dropout: 0.45/" -i "" params.yaml
dvc repro train
git add .
tick
git commit -am "Reproduce model using dropout = 0.45"
git tag -a "11-higher-dropout" -m "Model retrained using dropout = 0.45."

dvc repro evaluate
git add .
tick
git commit -am "Evaluate model with higher dropout"
git tag -a "high-dropout-experiment" -m "High dropout experiment evaluation"
git tag -a "12-high-dropout-experiment" -m "Evaluated high dropout model."
dvc push

mkdir -p .github/workflows
cp ../../code/cml.yaml .github/workflows/cml.yaml
git add .
tick
git commit -m "Create GitHub action with CML"
git tag -a "13-gh-action" -m "GitHub action created"

dvc metrics diff --show-md

popd

unset TAG_TIME
unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_DATE
unset GIT_AUTHOR_NAME
unset GIT_AUTHOR_EMAIL
unset GIT_COMMITTER_NAME
unset GIT_COMMITTER_EMAIL

hub delete -y $GIT_ORG/$REPO_NAME || true
cd build/$REPO_NAME
hub create $GIT_ORG/$REPO_NAME -d "Fashion MNIST DVC project" || true
ORIGIN_URL=https://github.com/$GIT_ORG/$REPO_NAME.git
git remote set-url origin $ORIGIN_URL
git branch -M main
git push -u origin main
git push --force origin --tags

cd ../..
rm -fR build