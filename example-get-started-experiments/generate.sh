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

export GIT_AUTHOR_NAME="David de la Iglesia"
export GIT_AUTHOR_EMAIL="daviddelaiglesiacastro@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

mkdir -p $REPO_PATH
pushd $REPO_PATH

virtualenv -p python3 .venv
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .venv/bin/activate
echo '.venv/' >> .gitignore
echo 'yolo*.pt' >> .gitignore
echo '/runs' >> .gitignore
echo '/weights' >> .gitignore
echo 'dvclive/report.html' >> .gitignore

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


cp -r $HERE/code/datasets .
git add datasets/.gitignore datasets/pool_data.dvc
tick
git commit -m "Add data"
dvc pull


cp -r $HERE/code/TrainSegModel.ipynb .
git add .
git commit -m "Add notebook using DVCLive"

sudo apt-get update && sudo apt-get install ffmpeg libsm6 libxext6 -y
pip install -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu118
pip install jupyter
yolo settings datasets_dir="/workspaces/example-repos-dev/example-get-started-experiments/build/example-get-started-experiments/datasets/"
yolo settings runs_dir="/workspaces/example-repos-dev/example-get-started-experiments/build/example-get-started-experiments/runs/"
yolo settings weights_dir="/workspaces/example-repos-dev/example-get-started-experiments/build/example-get-started-experiments/weights/"
jupyter nbconvert --execute 'TrainSegModel.ipynb' --inplace
git add .
tick
git commit -m "Run notebook and apply best experiment"
git tag -a "1-notebook-dvclive" -m "Experiment using Notebook"
gto register dvclive:pool-segmentation --version v0.1.0
gto assign dvclive:pool-segmentation --version v0.1.0 --stage dev


cp -r $HERE/code/src .
cp $HERE/code/params.yaml .

dvc stage add -n create_yolo_dataset \
  -d src/create_yolo_dataset.py -d datasets/pool_data \
  -o datasets/yolo_dataset/train -o  datasets/yolo_dataset/val \
  "python src/create_yolo_dataset.py \${create_yolo_dataset}"

dvc stage add -n train \
  -d src/train.py -d datasets/yolo_dataset/train -d datasets/yolo_dataset/val \
  "python src/train.py \${train}"

git rm TrainSegModel.ipynb
git add .
tick
git commit -m "Convert Notebook to dvc.yaml pipeline"


dvc exp run
git add .
tick
git commit -m "Run dvc.yaml pipeline"
git tag -a "2-dvc-pipeline" -m "Experiment using dvc pipeline"
gto register dvclive:pool-segmentation --version v0.2.0
gto assign dvclive:pool-segmentation --version v0.1.0 --stage prod
gto assign dvclive:pool-segmentation --version v0.2.0 --stage dev

export GIT_AUTHOR_NAME="Dave Berenbaum"
export GIT_AUTHOR_EMAIL="dave.berenbaum@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

dvc exp run --queue --set-param 'train.model=yolov8s-seg.pt,yolov8m-seg.pt,yolov8l-seg.pt' --message 'Tune model'
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
