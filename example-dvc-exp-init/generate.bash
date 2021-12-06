#!/usr/bin/env bash

set -veux

HERE="$( cd "$(dirname "$0")" ; pwd -P )"
export HERE
PROJECT_NAME="example-dvc-exp-init"
REPO_NAME="$(git rev-parse --short HEAD)-$(date +%F-%H-%M-%S)"
export REPO_NAME

export REPO_ROOT="${HERE}/build/${REPO_NAME}"

# Count the number of git tag calls in this repository
NUM_TAGS=$(grep 'git tag' ${HERE}/generate-* | wc -l)
# Start a bit more in the past
TOTAL_TAGS=$(( NUM_TAGS + 10 ))

export STEP_TIME=$(( RANDOM + 50000 ))
export TAG_TIME=$(( $(date +%s) - ( TOTAL_TAGS * STEP_TIME ) ))

export GIT_AUTHOR_NAME="Olivaw Owlet"
export GIT_AUTHOR_EMAIL="64868532+iterative-olivaw@users.noreply.github.com"
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

tag_tick() {
  export TAG_TIME=$(( TAG_TIME + STEP_TIME ))
  export GIT_AUTHOR_DATE=${TAG_TIME}
  export GIT_COMMITTER_DATE=${TAG_TIME}
}

export -f tag_tick

if [[ -d "$REPO_ROOT" ]]; then
    echo "Repo $REPO_ROOT already exists, please remove it first."
    exit 1
fi

mkdir -p "${REPO_ROOT}"
pushd "${REPO_ROOT}"


export REPO_PATH="${REPO_ROOT}/${PROJECT_NAME}"

mkdir -p "$REPO_PATH"
pushd "${REPO_PATH}"

virtualenv -p python3 .venv
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .venv/bin/activate
echo '.venv/' > .gitignore
# pip install 'dvc[all]'
pip install git+https://github.com/iterative/dvc.git 'dvc[all]'

git init
git checkout -b main
cp $HERE/code/README.md "${REPO_PATH}"
cp $HERE/.gitattributes "${REPO_PATH}"
cp $HERE/code/.gitignore "${REPO_PATH}"
tag_tick
git add .gitignore README.md
git commit -m "Initialized Git"
git tag "git-init"

cp -r "${HERE}"/code/src .
cp "${HERE}"/code/requirements.txt .
cp "${HERE}"/code/params.yaml .
pip install -r "${REPO_PATH}"/requirements.txt
tag_tick
git add .
git commit -m "Added source and params"
git tag "source-code"

test -d data/ || mkdir -p data/ 
pushd data
time dvc get https://github.com/iterative/dataset-registry \
        fashion-mnist/images.tar.gz -o images.tar.gz
time tar xvzf images.tar.gz
popd

time dvc init

# tag_tick
# git add .dvc
# git commit -m "Initialized DVC"
# git tag "dvc-init"
#
# dvc add data/images.tar.gz

time dvc exp init python3 src/train.py
## it doesn't add data/ so adding it manually
time dvc add data/
tag_tick
git add .
git commit -m "added .dvc, initialized experiment and added data"
git status 
git tag "dvc-exp-init-run"

# tag_tick
# add_main_pipeline
# git add dvc.yaml data/.gitignore models/.gitignore
# git commit -m "Added experiments pipeline"
# git tag "created-pipeline"
#
# tag_tick
# Remote active on this env only, for writing to HTTP redirect below.
dvc remote add --default --local storage s3://dvc-public/remote/example-dvc-experiments
dvc remote add --default storage https://remote.dvc.org/example-dvc-experiments
# git add .dvc
# git commit -m "Added DVC remote"
# git tag "configured-remote"

git tag "get-started"

time dvc exp run
tag_tick
git status
# git add models/.gitignore data/.gitignore dvc.lock logs.csv metrics.json
git add . 
git commit -m "Baseline experiment run"
git tag "baseline-experiment"

time dvc exp run -n cnn-32 --queue -S model.conv_units=32
time dvc exp run -n cnn-64 --queue -S model.conv_units=64
time dvc exp run -n cnn-96 --queue -S model.conv_units=96
time dvc exp run -n cnn-128 --queue -S model.conv_units=128

time dvc exp run --run-all --jobs 2

time dvc exp show --no-pager

git status

PUSH_SCRIPT="${REPO_ROOT}/push-${PROJECT_NAME}.bash"

cat > "${PUSH_SCRIPT}" <<EOF
#!/usr/bin/env bash

set -veux

# The Git repo generated by this script is intended to be published on
# https://github.com/iterative/${PROJECT_NAME}.git Make sure the Github repo
# exists first and that you have appropriate write permissions.

pushd ${REPO_PATH}

dvc remote add --force --default storage s3://dvc-public/remote/${PROJECT_NAME}/
dvc push

git remote add origin "git@github.com:iterative/${PROJECT_NAME}.git"

# Delete all tags in the remote
for tag in \$(git ls-remote --tags origin | grep -v '{}$' | cut -c 52-) ; do
    git push -v origin --delete \${tag}
done

# Delete all experiments in the remote
git ls-remote origin 'refs/exps/*' | cut -f 2 | while read exppath ; do
   git push -d origin "\${exppath}"
done

git push --force origin --all
# We use lightweight tags so --follow-tags don't work
git push --force origin --tags
dvc exp list --all --names-only | xargs -n 1 dvc exp push origin
popd
EOF

chmod u+x "${PUSH_SCRIPT}"

popd

cat << EOF
##################################
### REPOSITORY GENERATION DONE ###
##################################

Repositories are in:

${REPO_ROOT}

Push scripts are written to:
$(ls -1 ${REPO_ROOT}/*.bash)

You may remove the generated repo with:

$ rm -fR ${REPO_ROOT}
EOF

unset HERE
unset PROJECT_NAME
unset REPO_NAME
unset REPO_ROOT
unset STEP_TIME
unset TAG_TIME
unset GIT_AUTHOR_NAME
unset GIT_AUTHOR_EMAIL
unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_NAME
unset GIT_COMMITTER_EMAIL
unset GIT_COMMITTER_DATE
unset tag_tick
