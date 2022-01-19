#!/usr/bin/env bash

set -veux

HERE="$( cd "$(dirname "$0")" ; pwd -P )"
export HERE
PROJECT_NAME="example-cml"
PROJECT_SUFFIX="$(git rev-parse --short HEAD)-$(date +%F-%H-%M-%S)"

SEED_REPO="git@github.com:iterative/example_cml"

export REPO_ROOT="${HERE}/build/${PROJECT_NAME}-${PROJECT_SUFFIX}"

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

BRANCH_MODIFY_SCRIPT="modify-branch.bash"

mkdir -p "${REPO_ROOT}"
pushd "${REPO_ROOT}"

git clone "${SEED_REPO}"
SEED_DIR=$(basename "${SEED_REPO}")

hubs=(github)

git_remote_from_hub() {
    local hubname=$1
    local repo_name=$2
    case $hubname in
        github ) echo "git@github.com:iterative/${repo_name}"
            ;;
        * ) echo "No support for $hubname yet"
            exit 99
            ;;
    esac
}

for hub in ${hubs} ; do
    mkdir -p ${REPO_ROOT}/${hub}
    for source_dir in $(find ${HERE}/${hub} -maxdepth 1 -type d) ; do
        repo_name=$(basename ${source_dir})
        target_dir="${REPO_ROOT}/${hub}/${repo_name}"
        git clone --depth=1 ${SEED_DIR} ${target_dir}
        pushd ${target_dir}
        # Delete git to reinit
        rm -rf .git
        git --initial-branch=seed init
        git add *
        git add .*
        git commit -m "Initial commit from files in ${SEED_REPO}"
        git remote add origin "$(git_remote_from_hub $hubname $repo_name)"
        for branch_dir in $(find ${source_dir}  -maxdepth 1 -type d) ; do
            branch_name=$(basename ${branch_dir})
            git checkout -b ${branch_name}
            cp -r ${branch_dir}/* ${target_dir}
            if [[ -f  "${BRANCH_MODIFY_SCRIPT}" ]] ; then
                chmod u+x "${BRANCH_MODIFY_SCRIPT}"
                bash -c "${BRANCH_MODIFY_SCRIPT}"
                # remove not to check in the script to the repository
                rm -f "${BRANCH_MODIFY_SCRIPT}"
            fi

            git add *
            git add .*
            git commit -m "Modifications for ${branch_name}"
            git branch --set-upstream-to=origin/${branch_name}
            git status -s
            git checkout seed
        done
        popd
    done
done

## TODO: Our push script should push all generated repositories and DVC elements

# PUSH_SCRIPT="${REPO_ROOT}/push-${PROJECT_NAME}.bash"
#
# cat > "${PUSH_SCRIPT}" <<EOF
# #!/usr/bin/env bash
#
# set -veux
#
# pushd ${REPO_PATH}
#
# dvc remote add --force --default storage s3://dvc-public/remote/${PROJECT_NAME}/
# dvc push
#
# git remote add origin "git@github.com:iterative/${PROJECT_NAME}.git"
#
# # Delete all tags in the remote
# for tag in \$(git ls-remote --tags origin | grep -v '{}$' | cut -c 52-) ; do
#     git push -v origin --delete \${tag}
# done
#
# # Delete all experiments in the remote
# git ls-remote origin 'refs/exps/*' | cut -f 2 | while read exppath ; do
#    git push -d origin "\${exppath}"
# done
#
# git push --force origin --all
# # We use lightweight tags so --follow-tags don't work
# git push --force origin --tags
# dvc exp list --all --names-only | xargs -n 1 dvc exp push origin
# popd
# EOF
#
# chmod u+x "${PUSH_SCRIPT}"
#
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
