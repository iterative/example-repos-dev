#!/bin/bash
# See https://dvc.org/get-started

set -eux

HERE=$( cd "$(dirname "$0")" ; pwd -P )
REPO_NAME="example-get-started"
REPO_PATH_BASE="$HERE/build/$REPO_NAME"
PROD=${1:-false}

# Some additional options to tune the exact repo structure that we generate.
# It useful to generate nested (monorepo), private storages, a mix of those
# cases to be used in Studio fixtures or QA.
OPT_TESTING_REPO='false' # Default false.
OPT_SUBDIR='' # No leading or trailing slashes. Default "".
OPT_INIT_GIT='true' # Default true.
OPT_INIT_DVC='true' # Default true.
OPT_NON_DVC='false' # Default false.
OPT_BRANCHES='true' # Default true.
OPT_TAGS='true' # Default true.
# Default "public-s3". Other options: "public-s3", "private-http", "private-ssh", etc.
# See the details below in the `init_remote_storage` and in the README.
OPT_REMOTE='public-s3'
OPT_DVC_TRACKED_METRICS='false' # Default false.
OPT_REGISTER_MODELS='true' # Default true.
OPT_MODEL_NAME='text-classification' # Default "text-classification".
OPT_TAG_MODELS='true' # Default true.
OPT_SQUASH_COMMITS='false' # Default false.


if [ -z $OPT_SUBDIR ]; then
  COMMIT_PREFIX=""
  GIT_TAG_SUFFIX=""
  GTO_PREFIX=""
  MAIN_REPO_README=""
else
  [ -d "$REPO_PATH_BASE" ] && cp -r "$REPO_PATH_BASE" "${REPO_PATH_BASE}-backup-$(date +%s)"
  MODIFIER=$(echo ${OPT_SUBDIR} | tr / -)
  COMMIT_PREFIX="[$MODIFIER] "
  GIT_TAG_SUFFIX="-$MODIFIER"
  # In GTO we use : as a separator to get the full model name
  GTO_PREFIX="${OPT_SUBDIR}:"
  MAIN_REPO_README="${REPO_PATH_BASE}/README.md"
fi

REPO_PATH="${REPO_PATH_BASE}/${OPT_SUBDIR}"
if [ -d "$REPO_PATH" ]; then
  echo "Repo $REPO_PATH already exists, please remove it first."
  exit 1
fi

create_tag() {
  if [ $OPT_TAGS == 'true' ]; then
    git tag -a "$1" -m "$2"
  fi
}

init_remote_storage() {
  if [ $OPT_REMOTE == 'public-s3' ]; then
    # Remote active on this env only, for writing.
    dvc remote add -f -d --local $OPT_REMOTE s3://dvc-public/remote/get-started
    # Actual remote for generated project (read-only). Redirect of S3 bucket above.
    dvc remote add -f -d $OPT_REMOTE https://remote.dvc.org/get-started
  fi

  if [ $OPT_REMOTE == 'private-s3' ]; then
    dvc remote add -f -d $OPT_REMOTE s3://dvc-private/remote/get-started
  fi

  if [ $OPT_REMOTE == 'private-http' ]; then
    dvc remote add -f -d --local storage ssh://dvc@35.194.53.251/home/dvc/storage
    dvc remote modify --local storage keyfile /Users/ivan/.ssh/dvc_gcp_remotes_rsa
    dvc remote add -f -d $OPT_REMOTE http://35.194.53.251
  fi

  if [ $OPT_REMOTE == 'private-ssh' ]; then
    dvc remote add -f -d $OPT_REMOTE ssh://dvc@35.194.53.251/home/dvc/storage
    dvc remote modify $OPT_REMOTE keyfile /Users/ivan/.ssh/dvc_gcp_remotes_rsa
  fi

  if [ $OPT_REMOTE == 'private-azure' ]; then
    # Make sure that you have connection string in your env or some other way
    # provide credentials for the `dvcprivate` storage account. Copy the connection
    # string from the Azure portal and export it with
    # `AZURE_STORAGE_CONNECTION_STRING`
    dvc remote add -f -d $OPT_REMOTE azure://nlp
  fi
}

mkdir -p $REPO_PATH
pushd $REPO_PATH

TOTAL_TAGS=50
STEP_TIME=500000

if [ $(git rev-parse --show-toplevel) == $REPO_PATH_BASE ]; then
  BEGIN_TIME=$(git log -1 --format=%ct)
else
  BEGIN_TIME=$(( $(date +%s) - (${TOTAL_TAGS} * ${STEP_TIME}) ))
fi

export TAG_TIME=${BEGIN_TIME}
export GIT_AUTHOR_DATE="${TAG_TIME} +0000"
export GIT_COMMITTER_DATE="${TAG_TIME} +0000"

tick(){
  TICK_DELTA=$(python3 -c "print(int(${STEP_TIME} * ($RANDOM+1)/32767))")
  export TAG_TIME=$(( ${TAG_TIME} + ${TICK_DELTA} ))
  export GIT_AUTHOR_DATE="${TAG_TIME} +0000"
  export GIT_COMMITTER_DATE="${TAG_TIME} +0000"
}

if [ $OPT_TESTING_REPO == 'true' ]; then
  export GIT_AUTHOR_NAME="R. Daneel Olivaw"
  export GIT_AUTHOR_EMAIL="olivaw@iterative.ai"
else
  export GIT_AUTHOR_NAME="Ivan Shcheklein"
  export GIT_AUTHOR_EMAIL="shcheklein@gmail.com"
fi
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

virtualenv -p python3 .venv
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .venv/bin/activate
echo '.venv/' > .gitignore

# Installing from main since we'd like to update repo before
# the release
pip install "git+https://github.com/iterative/dvc#egg=dvc[all]" gto


if [ $OPT_INIT_GIT == 'true' ]; then
  git init
  cp $HERE/code/README.md .
  cp $HERE/code/.devcontainer.json .
  cp $HERE/code/.gitattributes .
  git add .
else
  git checkout main
fi

# Dump the config for the repo into README if we are generating a testing repo.
if [ $OPT_TESTING_REPO == 'true' ]; then
  echo -e "This is a [DVC Studio](https://studio.iterative.ai) testing (fixture) repository." > README.md
  echo -e "\n## \`<root>/${OPT_SUBDIR}\` config\n\n\`\`\`bash" | tee -a README.md $MAIN_REPO_README
  while read var; do
    echo "$var='$(eval "echo \"\$$var\"")'" | tee -a README.md $MAIN_REPO_README
  done < <( declare -p | cut -d " " -f 2 | grep = | grep "^OPT_" | cut -f 1 -d '=')
  echo '```' | tee -a README.md $MAIN_REPO_README
  git add $REPO_PATH_BASE/.
fi

if [ $OPT_INIT_GIT == 'true' ] || [ $OPT_TESTING_REPO == 'true' ]; then
  if [ $OPT_INIT_GIT == 'true' ]; then
    tick
    git commit -m "${COMMIT_PREFIX}Initialize Git repository"
    create_tag "0-git-init${GIT_TAG_SUFFIX}" "Git initialized."
  else
    tick
    git commit -m "${COMMIT_PREFIX}Add testing repo"
    create_tag "0-git-init${GIT_TAG_SUFFIX}" "Testing repo initialized."
  fi
fi

BASE_COMMT=$(git rev-parse HEAD)

if [ $OPT_INIT_DVC == 'true' ]; then
  dvc init --subdir
  tick
  git commit -m "${COMMIT_PREFIX}Initialize DVC project"
  create_tag "1-dvc-init${GIT_TAG_SUFFIX}" "DVC initialized."
fi


mkdir data
dvc get https://github.com/iterative/dataset-registry \
  get-started/data.xml -o data/data.xml

if [ $OPT_NON_DVC == 'false' ]; then
  if [ $OPT_REGISTER_MODELS == "true" ]; then
    echo "artifacts:
  stackoverflow-dataset:
    path: data/data.xml
    type: dataset
    desc: Initial XML StackOverflow dataset (raw data)" >> dvc.yaml
  fi
  dvc add data/data.xml
  git add data/data.xml.dvc
else
  echo "data.xml" > data/.gitignore
fi
git add data/.gitignore
tick
git commit -m "${COMMIT_PREFIX}Add raw data"
create_tag "2-track-data${GIT_TAG_SUFFIX}" "Data file added."


if [ $OPT_NON_DVC == 'false' ]; then
  init_remote_storage

  git add $REPO_PATH_BASE/.
  tick
  git commit -m "${COMMIT_PREFIX}Configure default remote"
  create_tag "3-config-remote${GIT_TAG_SUFFIX}" "Remote storage configured."
  dvc push
fi

if [ $OPT_NON_DVC == 'false' ]; then
  rm data/data.xml data/data.xml.dvc
  dvc import https://github.com/iterative/dataset-registry \
    get-started/data.xml -o data/data.xml
  git add data/data.xml.dvc
  tick
  git commit -m "${COMMIT_PREFIX}Import raw data (overwrite)"
  create_tag "4-import-data${GIT_TAG_SUFFIX}" "Data file overwritten with an import."
  dvc push
fi

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
if [ $OPT_NON_DVC == 'true' ]; then
cat <<EOF >> metrics.json
{
    "avg_prec": {
        "train": 0.9743681430252835,
        "test": 0.9249974999612706
    },
    "roc_auc": {
        "train": 0.9866678562450621,
        "test": 0.9460213440787918
    }
}
EOF
fi
tick
git commit -m "${COMMIT_PREFIX}Add source code files to repo"
create_tag "5-source-code${GIT_TAG_SUFFIX}" "Source code added."

if [ $OPT_NON_DVC == 'false' ]; then
  dvc stage add -n prepare \
    -p prepare.seed,prepare.split \
    -d src/prepare.py -d data/data.xml \
    -o data/prepared \
    python src/prepare.py data/data.xml
  dvc repro
  git add data/.gitignore dvc.yaml dvc.lock
  tick
  git commit -m "${COMMIT_PREFIX}Create data preparation stage"
  create_tag "6-prepare-stage${GIT_TAG_SUFFIX}" "First pipeline stage (data preparation) created."
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

  if [ $OPT_REGISTER_MODELS == "true" ]; then
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
repo.artifacts.add("$OPT_MODEL_NAME", artifact)
EOF
  fi

  git add .gitignore data/.gitignore dvc.yaml dvc.lock
  tick
  git commit -m "${COMMIT_PREFIX}Create ML pipeline stages"
  create_tag "7-ml-pipeline${GIT_TAG_SUFFIX}" "ML pipeline created."
  dvc push

  if [ $OPT_DVC_TRACKED_METRICS == "true" ]; then
    dvc stage add -n evaluate \
      -d src/evaluate.py -d model.pkl -d data/features \
      -o eval/metrics.json -o eval/plots \
      python src/evaluate.py model.pkl data/features
  else
    dvc stage add -n evaluate \
      -d src/evaluate.py -d model.pkl -d data/features \
      python src/evaluate.py model.pkl data/features
  fi

  dvc repro
  git add .gitignore dvc.yaml dvc.lock eval
  tick
  git commit -am "${COMMIT_PREFIX}Create evaluation stage"
  create_tag "8-dvclive-eval${GIT_TAG_SUFFIX}" "DVCLive evaluation stage created."
  dvc push

  sed -e 's/Live(\(.*\))/(\1, dvcyaml=False)/' src/evaluate.py

  echo "metrics:
- eval/metrics.json
plots:
- ROC:
    template: simple
    x: fpr
    y:
      eval/plots/sklearn/roc/train.json: tpr
      eval/plots/sklearn/roc/test.json: tpr
- Confusion-Matrix:
    template: confusion
    x: actual
    y:
      eval/plots/sklearn/cm/train.json: predicted
      eval/plots/sklearn/cm/test.json: predicted
- Precision-Recall:
    template: simple
    x: recall
    y:
      eval/plots/sklearn/prc/train.json: precision
      eval/plots/sklearn/prc/test.json: precision
- eval/plots/images/importance.png" >> dvc.yaml
  dvc repro
  git add .gitignore dvc.yaml dvc.lock eval
  tick
  git commit -am "${COMMIT_PREFIX}Customize evaluation plots"
  create_tag "9-custom-eval${GIT_TAG_SUFFIX}" "Custom evaluation stage created."
  create_tag "baseline-experiment${GIT_TAG_SUFFIX}" "Baseline experiment evaluation"
  if [ $OPT_TAG_MODELS == "true" ]; then
    gto register "${GTO_PREFIX}${OPT_MODEL_NAME}" --version v1.0.0
    gto assign "${GTO_PREFIX}${OPT_MODEL_NAME}" --version v1.0.0 --stage prod
  fi
  dvc push


  sed -e "s/max_features: 100/max_features: 200/" -i".bck" params.yaml
  sed -e "s/ngrams: 1/ngrams: 2/" -i".bck" params.yaml
  rm -f params.yaml.bck
  dvc repro train
  tick
  git commit -am "${COMMIT_PREFIX}Reproduce model using bigrams"
  create_tag "10-bigrams-model${GIT_TAG_SUFFIX}" "Model retrained using bigrams."
  if [ $OPT_TAG_MODELS == "true" ]; then
    gto register "${GTO_PREFIX}${OPT_MODEL_NAME}" --version v1.1.0
    gto assign "${GTO_PREFIX}${OPT_MODEL_NAME}" --version v1.1.0 --stage stage
  fi
  dvc push


  dvc repro evaluate
  tick
  git commit -am "${COMMIT_PREFIX}Evaluate bigrams model"
  create_tag "bigrams-experiment${GIT_TAG_SUFFIX}" "Bigrams experiment evaluation"
  create_tag "11-bigrams-experiment${GIT_TAG_SUFFIX}" "Evaluated bigrams model."
  if [ $OPT_TAG_MODELS == "true" ]; then
    gto register "${GTO_PREFIX}${OPT_MODEL_NAME}" --version v1.2.0
    gto assign "${GTO_PREFIX}${OPT_MODEL_NAME}" --version v1.2.0 --stage dev
  fi
  dvc push
fi

if [ $OPT_SQUASH_COMMITS == 'true' ]; then
  git reset --soft $BASE_COMMT
  git commit --amend --no-edit
fi

if [ $OPT_NON_DVC == 'false' ] && [ $OPT_BRANCHES == 'true' ]; then
  export GIT_AUTHOR_NAME="Dave Berenbaum"
  export GIT_AUTHOR_EMAIL="dave.berenbaum@gmail.com"
  export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
  export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

  git checkout -b "tune-hyperparams${GIT_TAG_SUFFIX}"

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
  git commit -am "${COMMIT_PREFIX}Run experiments tuning random forest params"
  create_tag "random-forest-experiments${GIT_TAG_SUFFIX}" "Run experiments to tune random forest params"
  create_tag "12-random-forest-experiments${GIT_TAG_SUFFIX}" "Tuned random forest classifier."
  dvc push

  git checkout main

  export GIT_AUTHOR_NAME="Dmitry Petrov"
  export GIT_AUTHOR_EMAIL="dmitry.petrov@nevesomo.com"
  export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
  export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"

  git checkout -b "try-large-dataset${GIT_TAG_SUFFIX}"

  dvc update data/data.xml.dvc --rev get-started-40K
  sed -e "s/max_features: 200/max_features: 500/" -i".bck" params.yaml
  rm -f params.yaml.bck
  dvc repro
  dvc push
  git commit -am "${COMMIT_PREFIX}Try a 40K dataset (4x data)"
fi

popd

unset TAG_TIME
unset GIT_AUTHOR_DATE
unset GIT_COMMITTER_DATE
unset GIT_AUTHOR_NAME
unset GIT_AUTHOR_EMAIL
unset GIT_COMMITTER_NAME
unset GIT_COMMITTER_EMAIL

set +eux
echo
echo "=========================================="
echo "Done! Read README for the next steps."
echo "=========================================="
echo
