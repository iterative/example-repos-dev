A set of scripts to generate an NLP DVC Studio project with multiple branches,
commit history, experiments, metrics, plots, etc. It used in the DVC docs and in
Studio as a demo project. 

This script can be also used in an advanced scenario to generate a nested
mono-repositories that are used as fixtures in Studio testing, or testing
different remote types. See the section below for the advanced settings.

## Demo project

Note! In some cases, before rebuilding the project you might want to delete the
existing remote tags if you change the order, or names.

```shell
git clone git@github.com:<slug>/example-get-started.git
cd example-get-started
git tag -l | xargs -n 1 git push --delete origin
```

For the basic use case (docs and Studio demo), use the command below.

```shell
./generate.sh
```

If change source code, to publish it on S3 (needed for the get started tutorial)
pass `true` to the command. It's needed when you ready to publish it.

```shell
./generate.sh true
```

The repo generated in `build/example-get-started` is intended to be published on
to the https://github.com/iterative/example-get-started. Make sure the Github
repo exists first and that you have appropriate write permissions.

To create it with https://cli.github.com/, run:

```shell
gh repo create iterative/example-get-started --public \
     -d "Get Started DVC project" -h "https://dvc.org/doc/get-started"
```

Run these commands to force push it:

```shell
cd build/example-get-started
git remote add origin git@github.com:<slug>/example-get-started.git
git push --force origin main
git push --force origin try-large-dataset
git push --force origin tune-hyperparams
# we push git tags one by one for Studio to receive webhooks:
git tag --sort=creatordate | xargs -n 1 git push --force origin
```

Run these to drop and then rewrite the experiment references on the repo:

```shell
source .venv/bin/activate
dvc exp remove -A -g origin
dvc exp push origin -A
```

To create a PR from the `try-large-dataset` branch:

```shell
gh pr create -t "Try 40K dataset (4x data)" \
   -b "We are trying here a large dataset, since the smaller one looks unstable" \
   -B main -H try-large-dataset
```

To create a PR from the `tune-hyperparams` branch:

```shell
gh pr create -t "Run experiments tuning random forest params" \
   -b "Better RF split and number of estimators based on small grid search." \
   -B main -H tune-hyperparams
```

Finally, return to the directory where you started:

```shell
cd ../..
```

You may remove the generated repo with:

```shell
rm -fR build/example-get-started
```

To update the project in Studio, follow the instructions at:

https://github.com/iterative/studio/wiki/Updating-and-synchronizing-demo-project


## Advanced usage

Inside the script there a few options that could help generating advanced nested
repositories and/or use different remote types.

- `OPT_TESTING_REPO='false'` - (default `false`). Set to true to generate a
  fixture repo or a testing repo. It generates a `README` in those repos that
  has the dump of all the settings that were used to generate them. This way it
  can be reproduced next time.
- `OPT_SUBDIR=''` - (default `''`). No leading or trailing slashes. If specified
  the new repo will be created inside the 
  `build/example-get-started/$OPT_SUBDIR` path.
- `OPT_INIT_GIT='true'` - (default `true`). Whether to run or not `git init`. If
  there is already initialized Git repo in place we don't need to run it again.
  Usually needed if you are generating a nested repo.
- `OPT_INIT_DVC='true'` - (default `true`). Whether to run or not
  `dvc init` in the generated directory. If it's nested directory `--subdir` is
  added.
- `OPT_NON_DVC='false'` - (default `false`). To generate a non DVC repo with
  some sources, basic params, and metrics. To test non DVC root, or custom
  metrics, etc.
- `OPT_BRANCHES='true'` - (default `true`). Whether we need to generate
  branches (bigger dataset, etc). It supports nested repos - branch names will
  have prefixes or suffixes to distinguish them.
- `OPT_REMOTE="public-s3"` - (default `private-s3`). Other options: `public-s3`,
  `private-http`, `private-ssh`, etc.
- `OPT_DVC_TRACKED_METRICS='false'` - (default `false`). Either we should use
  DVC to also track all metric and plot files (e.g. to test that Studio can get
  plots from the remote storage).
- `OPT_REGISTER_MODELS='false'` - (default `true`). Use the `gto` to register
  models. It supports nested repos.

## Remotes

A variety of remotes could be used to generated different repositories to test
private storage credentials in Studio (manually or via CI).

`OPT_REMOTE` takes different values (see above or in the `generate.sh`).

For SSH and HTTP remotes we use a machine that is deployed in GCP with IP
address http://35.194.53.251. Credentials for both could be found in this Slack
[thread](https://iterativeai.slack.com/archives/CUSNDR35K/p1595393188054200).
You might need to change a path to SSH key in the script. HTTP remote doesn't
support PUT/POST so we use SSH to upload data there.
