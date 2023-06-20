#!/bin/bash
# See https://dvc.org/doc/tutorials/get-started

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.
set -eux

HERE="$( cd "$(dirname "$0")" ; pwd -P )"
REPO_NAME="example-get-started"
REPO_PATH="$HERE/build/$REPO_NAME"
PROD=${1:-false}

if [ -d "$REPO_PATH" ]; then
  echo "Repo $REPO_PATH already exists, please remove it first."
  exit 1
fi

TOTAL_TAGS=15
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

export GIT_AUTHOR_NAME="Ivan Shcheklein"
export GIT_AUTHOR_EMAIL="shcheklein@gmail.com"
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
pip install "git+https://github.com/iterative/dvc#egg=dvc[all]" gto

git init
cp $HERE/code/README.md .
cp $HERE/code/.devcontainer.json .
cp $HERE/code/.gitattributes .
git add .
tick
git commit -m "Initialize Git repository"
git tag -a "0-git-init" -m "Git initialized."

dvc init
tick
git commit -m "Initialize DVC project"
git tag -a "1-dvc-init" -m "DVC initialized."

mkdir data
dvc get https://github.com/iterative/dataset-registry \
  get-started/data.xml -o data/data.xml
python <<EOF
from dvc.repo import Repo
from dvc.annotations import Artifact

repo = Repo(".")
artifact = Artifact(path="data/data.xml", desc="Initial XML StackOverflow dataset (raw data)")
repo.artifacts.add("stackoverflow-dataset", artifact)
EOF

dvc add data/data.xml
git add data/.gitignore data/data.xml.dvc
tick
git commit -m "Add raw data"
git tag -a "2-track-data" -m "Data file added."

# Remote active on this env only, for writing to HTTP redirect below.
dvc remote add -d --local storage s3://dvc-public/remote/get-started
# Actual remote for generated project (read-only). Redirect of S3 bucket above.
dvc remote add -d storage https://remote.dvc.org/get-started
git add .
tick
git commit -m "Configure default remote"
git tag -a "3-config-remote" -m "Read-only remote storage configured."
dvc push

rm data/data.xml data/data.xml.dvc
dvc import https://github.com/iterative/dataset-registry \
  get-started/data.xml -o data/data.xml
git add data/data.xml.dvc
tick
git commit -m "Import raw data (overwrite)"
git tag -a "4-import-data" -m "Data file overwritten with an import."
dvc push

# Deploy code
pushd $HERE
source deploy.sh $PROD
popd

# Get deployed code
if [ $PROD == 'prod' ]; then
    wget https://code.dvc.org/get-started/code.zip
else
    mv $HERE/code.zip code.zip
fi

unzip code.zip
rm -f code.zip
pip install -r src/requirements.txt
git add .
tick
git commit -m "Add source code files to repo"
git tag -a "5-source-code" -m "Source code added."


dvc stage add -n prepare \
  -p prepare.seed,prepare.split \
  -d src/prepare.py -d data/data.xml \
  -o data/prepared \
  python src/prepare.py data/data.xml
dvc repro
git add data/.gitignore dvc.yaml dvc.lock
tick
git commit -m "Create data preparation stage"
git tag -a "6-prepare-stage" -m "First pipeline stage (data preparation) created."
dvc push


dvc stage add -n featurize \
  -p featurize.max_features,featurize.ngrams \
  -d src/featurization.py -d data/prepared \
  -o data/features \
  python src/featurization.py \
  data/prepared data/features
dvc stage add -n train \
  -p train.seed,train.n_est,train.min_split \
  -d src/train.py -d data/features \
  -o model.pkl \
  python src/train.py data/features model.pkl
dvc repro
python <<EOF
from dvc.repo import Repo
from dvc.annotations import Artifact

repo = Repo(".")
artifact = Artifact(
  path="model.pkl", 
  type="model",
  desc="Detect whether the given stackoverflow question should have R language tag",
  labels=["nlp", "classification", "stackoverflow"]
)
repo.artifacts.add("text-classification", artifact)
EOF

git add .gitignore data/.gitignore dvc.yaml dvc.lock
tick
git commit -m "Create ML pipeline stages"
git tag -a "7-ml-pipeline" -m "ML pipeline created."
dvc push


dvc stage add -n evaluate \
  -d src/evaluate.py -d model.pkl -d data/features \
  -M eval/live/metrics.json -O eval/live/plots \
  -O eval/prc -o eval/importance.png \
  python src/evaluate.py model.pkl data/features
echo "plots:
  - ROC:
      template: simple
      x: fpr
      y:
        eval/live/plots/sklearn/roc/train.json: tpr
        eval/live/plots/sklearn/roc/test.json: tpr
  - Confusion-Matrix:
      template: confusion
      x: actual
      y:
        eval/live/plots/sklearn/cm/train.json: predicted
        eval/live/plots/sklearn/cm/test.json: predicted
  - Precision-Recall:
      template: simple
      x: recall
      y:
        eval/prc/train.json: precision
        eval/prc/test.json: precision
  - eval/importance.png" >> dvc.yaml
dvc repro
git add .gitignore dvc.yaml dvc.lock eval
tick
git commit -m "Create evaluation stage"
git tag -a "8-evaluation" -m "Baseline evaluation stage created."
git tag -a "baseline-experiment" -m "Baseline experiment evaluation"
gto register text-classification --version v1.0.0
dvc push


sed -e "s/max_features: 100/max_features: 200/" -i".bkp" params.yaml
sed -e "s/ngrams: 1/ngrams: 2/" -i".bkp" params.yaml
dvc repro train
tick
git commit -am "Reproduce model using bigrams"
git tag -a "9-bigrams-model" -m "Model retrained using bigrams."
gto register text-classification --version v1.1.0
dvc push


dvc repro evaluate
tick
git commit -am "Evaluate bigrams model"
git tag -a "bigrams-experiment" -m "Bigrams experiment evaluation"
git tag -a "10-bigrams-experiment" -m "Evaluated bigrams model."
gto register text-classification --version v1.2.0
dvc push


export GIT_AUTHOR_NAME="Dave Berenbaum"
export GIT_AUTHOR_EMAIL="dave.berenbaum@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

git checkout -b "tune-hyperparams"

unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_DATE

dvc exp run --queue --set-param train.min_split=8
dvc exp run --queue --set-param train.min_split=64
dvc exp run --queue --set-param train.min_split=2 --set-param train.n_est=100
dvc exp run --queue --set-param train.min_split=8 --set-param train.n_est=100
dvc exp run --queue --set-param train.min_split=64 --set-param train.n_est=100
dvc exp run --run-all -j 2
# Apply best experiment
EXP=$(dvc exp show --csv --sort-by avg_prec.test | tail -n 1 | cut -d , -f 1)
dvc exp apply $EXP
tick
git commit -am "Run experiments tuning random forest params"
git tag -a "random-forest-experiments" -m "Run experiments to tune random forest params"
git tag -a "11-random-forest-experiments" -m "Tuned random forest classifier."
dvc push

git checkout main

export GIT_AUTHOR_NAME="Dmitry Petrov"
export GIT_AUTHOR_EMAIL="dmitry.petrov@nevesomo.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

git checkout -b "try-large-dataset"

dvc update data/data.xml.dvc --rev get-started-40K
sed -e "s/max_features: 200/max_features: 500/" -i".bkp" params.yaml
dvc repro
dvc push
git commit -am "Try a 40K dataset (4x data)"

popd

unset TAG_TIME
unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_DATE
unset GIT_AUTHOR_NAME
unset GIT_AUTHOR_EMAIL
unset GIT_COMMITTER_NAME
unset GIT_COMMITTER_EMAIL

echo "`cat <<EOF-

The Git repo generated by this script is intended to be published on
https://github.com/iterative/example-get-started. Make sure the Github repo
exists first and that you have appropriate write permissions.

To create it with https://cli.github.com/, run:

gh repo create iterative/example-get-started --public \
     -d "Get Started DVC project" -h "https://dvc.org/doc/get-started"

Run these commands to force push it:

cd build/example-get-started
git remote add origin git@github.com:<slug>/example-get-started.git
git push --force origin main
git push --force origin try-large-dataset
git push --force origin tune-hyperparams
git push --force origin --tags

Run these to drop and then rewrite the experiment references on the repo:

dvc exp remove -A -g origin
dvc exp push origin -A

To create a PR from the "try-large-dataset" branch:

gh pr create -t "Try 40K dataset (4x data)" \
   -b "We are trying here a large dataset, since the smaller one looks unstable" \
   -B main -H try-large-dataset

To create a PR from the "tune-hyperparams" branch:

gh pr create -t "Run experiments tuning random forest params" \
   -b "Better RF split and number of estimators based on small grid search." \
   -B main -H tune-hyperparams

To update the project in Studio, follow the instructions at:

https://github.com/iterative/studio/wiki/Updating-and-synchronizing-demo-project

Finally, return to the directory where you started:

cd ../..

You may remove the generated repo with:

rm -fR build

`"
