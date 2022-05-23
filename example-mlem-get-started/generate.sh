#!/bin/bash
# See https://mlem.ai/doc/get-started

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.
set -eux

HERE="$( cd "$(dirname "$0")" ; pwd -P )"
REPO_NAME="example-mlem-get-started"

BUILD_PATH="$HERE/build"

mkdir -p $BUILD_PATH
pushd $BUILD_PATH
if [ ! -d "$BUILD_PATH/.venv" ]; then
  virtualenv -p python3 .venv
  export VIRTUAL_ENV_DISABLE_PROMPT=true
  source .venv/bin/activate
  echo '.venv/' > .gitignore
  pip install "git+https://github.com/iterative/mlem#egg=mlem[all]"
  pip install -r $HERE/code/src/requirements.txt
fi
popd

source $BUILD_PATH/.venv/bin/activate

REPO_PATH="$HERE/build/$REPO_NAME"

#if [ -d "$REPO_PATH" ]; then
#  echo "Repo $REPO_PATH already exists, please remove it first."
#  exit 1
#fi

TOTAL_TAGS=12
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

export GIT_AUTHOR_NAME="Mikhail Sveshnikov"
export GIT_AUTHOR_EMAIL="mike0sv@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"



mkdir -p $REPO_PATH
pushd $REPO_PATH

git init -b main
cp $HERE/code/README.md .
cp -r $HERE/code/.devcontainer .
cp $HERE/.gitattributes .
cp $HERE/code/src/requirements.txt .
cp $HERE/code/src/*.py .
echo ".venv" > .gitignore
git add .
tick
git commit -m "Initialize Git repository"
git tag -a "0-git-init" -m "Git initialized."


################## MLEM

git branch simple
git checkout simple

mlem init
tick
git add .mlem/config.yaml
git commit -m "Initialize MLEM project"
git tag -a "1-mlem-init" -m "MLEM initialized."


python train.py
git add .mlem/model
tick
git commit -m "Train the model"
git tag -a "2-train" -m "Model trained."


python evaluate.py
mlem apply rf iris.csv
echo "sepal length (cm),sepal width (cm),petal length (cm),petal width (cm)
0,1,2,3" > new_data.csv
mlem apply rf new_data.csv -i --it pandas[csv]
git add metrics.json
tick
git commit -m "Evaluate model"
git tag -a "3-eval" -m "Metrics calculated"


mlem init s3://example-mlem-get-started
mlem clone rf s3://example-mlem-get-started/rf


mlem create packager pip pip_config -c target=build/ -c package_name=example_mlem_get_started
git add .mlem/packager/pip_config.mlem
tick
git commit -m "Add package config"
git tag -a "4-pack" -m "Pip package config added"

mlem create env heroku staging
mlem create deployment heroku myservice -c app_name=example-mlem-get-started -c model=rf -c env=staging
git add .mlem/env/staging.mlem .mlem/deployment/myservice.mlem
tick
git commit -m "Add env and deploy meta"
git tag -a "5-deploy-meta" -m "Target env and deploy meta added"

if heroku apps:info example-mlem-get-started; then
  heroku apps:destroy example-mlem-get-started --confirm example-mlem-get-started
fi

mlem deploy create myservice
git add .mlem/deployment/myservice.mlem
tick
git commit -m "Deploy service"
git tag -a "6-deploy-create" -m "Deployment created"


###################### DVC

git checkout main
git branch dvc
git checkout dvc

mlem init
tick
git add .mlem/config.yaml
git commit -m "Initialize MLEM project"
git tag -a "1-dvc-mlem-init" -m "MLEM initialized."

dvc init
dvc remote add myremote --local azure://example-mlem
dvc remote add default -d https://examplemlem.blob.core.windows.net/example-mlem
git add .dvc
tick
git commit -m "Init dvc"
git tag -a "2-dvc-dvc-init" -m "DVC Initialized"


mlem config set default_storage.type dvc
echo "/**/?*.mlem" > .dvcignore
git add .dvcignore .mlem
tick
git commit -m "Configure MLEM for DVC"
git tag -a "3-dvc-mlme-config" -m "Configured MLEM to work with DVC"

python train.py
python evaluate.py
dvc add .mlem/model/rf .mlem/dataset/*.csv
git add .mlem .dvc metrics.json
tick
git commit -m "Run code with DVC"
git tag -a "4-dvc-save-models" -m "Saved models with DVC storage"
dvc push -r myremote

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
https://github.com/iterative/example-mlem-get-started.
Make sure the Github repo exists first and that you have
appropriate write permissions.

To create it with https://cli.github.com/, run:

gh repo create iterative/example-mlem-get-started --public \
     -d "Get Started MLEM project" -h "https://mlem.ai/doc/get-started"

Run these commands to force push it:

cd build/example-mlem-get-started
git remote add origin  https://github.com/iterative/example-mlem-get-started
git push --force origin main simple dvc
git push --force origin --tags
cd ../../

You may remove the generated repo with:

rm -fR build

`"
