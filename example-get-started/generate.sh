#!/bin/sh

# e Exit immediately if a command exits with a non-zero exit status.
# u Treat unset variables as an error when substituting.
# x Print commands and their arguments as they are executed.
set -eux

THIS="$( cd "$(dirname "$0")" ; pwd -P )"
REPO_NAME="example-get-started"
REPO_PATH="../$REPO_NAME"

if [ -d "$REPO_PATH" ]; then
    echo "Repo $REPO_NAME already exists, remove it first"
    exit 1
fi

mkdir $REPO_PATH
pushd $REPO_PATH

git init

virtualenv -p python3 .env
export VIRTUAL_ENV_DISABLE_PROMPT=true
source .env/bin/activate
echo '.env/' >> .gitignore

git add .
git commit -a -m  "initialize Git"
git tag -a "0-empty" -m "Git is initialized"

pip install dvc[s3]

dvc init
git commit -m "initialize DVC"
git tag -a "1-initialize" -m "DVC is initialized"

dvc remote add -d storage https://remote.dvc.org/get-started
dvc remote add -d --local storage s3://dvc-storage/get-started
git commit -a -m "add default HTTP remote"
git tag -a "2-remote" -m "remote initialized"

mkdir data
wget https://dvc.org/s3/get-started/data.xml -O data/data.xml
dvc add data/data.xml
git add data/.gitignore data/data.xml.dvc
git commit -m "add raw data to DVC"
git tag -a "3-add-file" -m "data file added"
dvc push

mkdir src
wget https://dvc.org/s3/get-started/code.zip
unzip code.zip
rm -f code.zip
echo "dvc[s3]" >> src/requirements.txt
cp $THIS/code/README.md $REPO_PATH
git add .
git commit -m 'add source code'
git tag -a "4-sources" -m "source code added"

pip install -r src/requirements.txt

dvc run -f prepare.dvc \
        -d src/prepare.py -d data/data.xml \
        -o data/prepared \
        python src/prepare.py data/data.xml
git add data/.gitignore prepare.dvc
git commit -m "add data preparation stage"
git tag -a "5-preparation" -m "first transformation stage added"
dvc push

dvc run -f featurize.dvc \
        -d src/featurization.py -d data/prepared \
        -o data/features \
        python src/featurization.py \
               data/prepared data/features
git add data/.gitignore featurize.dvc
git commit -m "add featurization stage"
git tag -a "6-featurization" -m "featurization stage added"
dvc push

dvc run -f train.dvc \
        -d src/train.py -d data/features \
        -o model.pkl \
        python src/train.py data/features model.pkl
git add .gitignore train.dvc
git commit -m "add train stage"
git tag -a "7-train" -m "train stage added"
dvc push

dvc run -f evaluate.dvc \
        -d src/evaluate.py -d model.pkl -d data/features \
        -M auc.metric \
        python src/evaluate.py model.pkl data/features auc.metric
git add .gitignore evaluate.dvc auc.metric
git commit -m "add evaluation stage"
git tag -a "baseline-experiment" -m "baseline experiment"
git tag -a "8-evaluation" -m "evaluation stage added"
dvc push

sed -e s/max_features=5000\)/max_features=6000\,\ ngram_range=\(1\,\ 2\)\)/ -i "" \
    src/featurization.py

dvc repro evaluate.dvc
git commit -a -m "try using bigrams"
git tag -a "bigrams-experiment" -m "bigrams experiment"
git tag -a "9-bigrams" -m "bigrams version added"
dvc push

popd

echo "`cat <<EOF-
Install 'hub' and run:

hub create iterative/example-get-started -d "Get started DVC project" \
-h "https://dvc.org/doc/get-started"
if you'd like to create the repository from scratch.

Make sure to delete the exising one on Github, save the tags and put them back
via UI interface when you done.

Run these commands manually in the generated get-started repo to rewrite the
eixisting repo:

git remote add origin git@github.com:iterative/example-get-started.git
git push --force origin master
git push --force origin --tags
`"
