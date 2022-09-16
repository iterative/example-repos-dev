#!/bin/bash

# Setup script env:
#   e   Exit immediately if a command exits with a non-zero exit status.
#   u   Treat unset variables as an error when substituting.
#   x   Print commands and their arguments as they are executed.
set -eux

PUSH=false
echo $#
if [ "$#" -eq 1 ] && [ "$0" != "--push" ]; then
  PUSH=true
  echo "Will push things to GitHub :tada:"
fi

HERE="$(
  cd "$(dirname "$0")"
  pwd -P
)"
USER_NAME="iterative"
REPO_NAME="example-gto"

BUILD_PATH="$HERE/build"
REPO_PATH="$BUILD_PATH/$REPO_NAME"

if [ -d "$REPO_PATH" ]; then
  echo "Repo $REPO_PATH already exists, please remove it first."
  exit 1
fi

mkdir -p $BUILD_PATH
pushd $BUILD_PATH
if [ ! -d "$BUILD_PATH/.venv" ]; then
  virtualenv -p python3 .venv
  source .venv/bin/activate
  echo '.venv/' >.gitignore
  pip install -r ../code/requirements.txt
  git clone https://github.com/iterative/gto.git
  pip install -e ./gto
fi
popd

source $BUILD_PATH/.venv/bin/activate

TOTAL_TAGS=15
STEP_TIME=100000
SLEEP_TIME=30
BEGIN_TIME=$(($(date +%s) - (${TOTAL_TAGS} * ${STEP_TIME})))
export TAG_TIME=${BEGIN_TIME}
export GIT_AUTHOR_DATE=${TAG_TIME}
export GIT_COMMITTER_DATE=${TAG_TIME}
tick() {
  export TAG_TIME=$((${TAG_TIME} + ${STEP_TIME}))
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
cp $HERE/code/.gitignore .
git add .gitignore
cp $HERE/code/requirements.txt .
cp $HERE/code/README.md .
cp -R $HERE/code/.github .
git add .
tick
git commit -m "Initialize Git repository with CI workflow"

if $PUSH; then
  # remove GH Actions workflows
  gh api repos/$USER_NAME/$REPO_NAME/actions/runs \
    --paginate -q '.workflow_runs[] | "\(.id)"' |
    xargs -n1 -I % gh api --silent repos/$USER_NAME/$REPO_NAME/actions/runs/% -X DELETE
  # add remote
  git remote add origin https://github.com/$USER_NAME/$REPO_NAME
  # remove all tags from remote
  git ls-remote --tags origin | awk '/^(.*)(\s+)(.*[a-zA-Z0-9])$/ {print ":" $2}' | xargs git push origin
fi

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
  sleep $SLEEP_TIME
fi

echo "Update the model"
echo "2nd version" >models/churn.pkl
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
  sleep $SLEEP_TIME
fi

echo "Promote models"
tick
gto assign churn --version v3.0.0 --stage dev
if $PUSH; then
  git push --tags
  sleep $SLEEP_TIME
fi

tick
gto assign churn HEAD --stage staging
if $PUSH; then
  git push --tags
  sleep $SLEEP_TIME
fi

tick
gto assign churn --version v3.0.0 --stage prod
if $PUSH; then
  git push --tags
  sleep $SLEEP_TIME
fi

tick
gto assign churn --version v3.1.0 --stage dev
gto assign segment --version v0.4.1 --stage dev
if $PUSH; then
  git push --tags
fi

echo "Add MLEM model"
tick
git checkout -b mlem
rm -rf .github
cp -R $HERE/code/mlem/ .
pip install -r requirements.txt
python train.py "The very first MLEM model"
git add .
git commit -m "Add MLEM model"

tick
gto assign churn --stage dev
if $PUSH; then
  git push --tags
fi


gto show
gto history


if $PUSH; then
  git push --set-upstream origin main mlem -f
  gh pr create --title "Add CI workflow to deploy MLEM model" \
      --body "Deploy MLEM model in CI as Git tag with Stage assignment was pushed to the repo. Check out the Actions, you could see that the model was indeed deployed to Heroku. See MLEM documentation at https://mlem.ai/doc/" \
      --base main \
      --head mlem
fi

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

To run the generator in the test mode, just use "bash generate.sh"

To push it to GitHub, use "bash generate.sh --push"
This will do it step by step waiting for CI to have consistent results.

To cd to the generated repo, run "cd build/example-gto"

You may remove the generated repo with "rm -fR build/example-gto"
EOF
