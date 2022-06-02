#!/bin/bash

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.
set -eux

PUSH=false
echo $#
if [ "$#" -eq 1 ] && [ "$0" != "--push" ]; then
   PUSH=true;
   echo "Will push things to GitHub :tada:"
fi

HERE="$( cd "$(dirname "$0")" ; pwd -P )"
USER_NAME="iterative"
REPO_NAME="example-gto"

BUILD_PATH="$HERE/build"

mkdir $BUILD_PATH
pushd $BUILD_PATH
if [ ! -d "$BUILD_PATH/.venv" ]; then
  virtualenv -p python3 .venv
  export VIRTUAL_ENV_DISABLE_PROMPT=true
  source .venv/bin/activate
  echo '.venv/' > .gitignore
  pip install gto
fi
popd

source $BUILD_PATH/.venv/bin/activate

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

export GIT_AUTHOR_NAME="Alexander Guschin"
export GIT_AUTHOR_EMAIL="1aguschin@gmail.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"



mkdir -p $REPO_PATH
pushd $REPO_PATH

git init -b main
cp -r $HERE/code/ .
git add .
tick
git commit -m "Initialize Git repository with CI workflow"

if $PUSH; then
  # remove GH Actions workflows
  gh api repos/$USER_NAME/$REPO_NAME/actions/runs \
    --paginate -q '.workflow_runs[] | "\(.id)"' | \
    xargs -n1 -I % gh api --silent repos/$USER_NAME/$REPO_NAME/actions/runs/% -X DELETE
  # add remote
  git remote add origin https://github.com/$USER_NAME/$REPO_NAME
  # remove all tags from remote
  git ls-remote --tags origin | awk '/^(.*)(\s+)(.*[a-zA-Z0-9])$/ {print ":" $2}' | xargs git push origin
fi

echo "Fix env"
pip freeze > requirements.txt
echo "Create new models"
mkdir models
echo "1st version" > models/churn.pkl
git add models requirements.txt
tick
git commit -am "Create models"

gto annotate churn --type model --path models/churn.pkl --must-exist
gto annotate segment --type model --path s3://mycorp/proj-ml/segm-model-2022-04-15.pt
gto annotate cv-class --type model --path s3://mycorp/proj-ml/classif-v2.pt
git add artifacts.yaml
tick
git commit -m "Annotate models with GTO"
if $PUSH; then
  git push --set-upstream origin main -f
fi

echo "Register new model"
tick
gto register churn --version v3.0.0
tick
gto register segment --version v0.4.1
tick
gto register cv-class --version v0.1.13
if $PUSH; then
  git push --tags
  sleep 60
fi

echo "Update the model"
echo "2nd version" > models/churn.pkl
tick
git commit -am "Update model"
if $PUSH; then
  git push
fi

echo "Register models"
tick
gto register churn --bump-minor
if $PUSH; then
  git push --tags
  sleep 60
fi

echo "Promote models"
tick
gto promote churn staging HEAD
if $PUSH; then
  git push --tags
  sleep 60
fi

tick
gto promote churn prod --version v3.0.0
if $PUSH; then
  git push --tags
  sleep 60
fi

tick
gto promote segment dev --version v0.4.1
if $PUSH; then
  git push --tags
fi

gto show
gto history

popd

unset TAG_TIME
unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_DATE
unset GIT_AUTHOR_NAME
unset GIT_AUTHOR_EMAIL
unset GIT_COMMITTER_NAME
unset GIT_COMMITTER_EMAIL

cat <<EOF

The Git repo generated by this script is intended to be published on
https://github.com/iterative/example-gto.
Make sure the Github repo exists first and that you have
appropriate write permissions.

To create it with https://cli.github.com/, run:

gh repo create iterative/example-gto --public \
     -d "Get Started GTO project"

Run these commands to force push it:

cd build/example-mlem-get-started
git remote add origin  https://github.com/iterative/example-gto
git push --force origin main
git push --force origin --tags
cd ../../

You may remove the generated repo with:

rm -fR build
EOF
