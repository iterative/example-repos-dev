# Get Started Tutorial (sources)

Contains source code and [Shell](https://www.shellscript.sh/) scripts to
generate and deploy example DVC repositories used in the [Get
Started](https://dvc.org/doc/get-started) and other sections of the DVC docs.

## Requirements

Please make sure you have these available on the environment where these scripts
will run:

- [Git](https://git-scm.com/)
- [Python](https://www.python.org/) 3 (with `python3` and [pip](https://pypi.org/project/pip/) commands)
- [Virtualenv](https://virtualenv.pypa.io/en/stable/)

## Naming Convention for Example Repositories

In order to have a consistent naming scheme across all example repositories, the
new repositories should be named as:

```
example-PROD-FEATURE
```

where `PROD` is one of the products like `dvc`, `cml`, `studio`, or `dvclive`, and `FEATURE` is
the feature that the repository focused on, like `experiments`, or `pipelines`.
You can also use additional keywords as suffix to differentiate from the others.

⚠️ Please create all new repositories with the prefix `example-`.

## Scripts

Each example DVC project is in each of the root directories (below). `cd` into
the directory first before running the desired script, for example:

```console
$ cd example-get-started
$ ./deploy.sh
```

### example-get-started

- `deploy.sh`: Makes and deploys code archive from
  [example-get-started/code](example-get-started/code) (downloaded as part of
  the `generate.sh`) to S3.
  > Requires AWS CLI and write access to `s3://dvc-public/code/get-started/`.

- `generate.sh`: Generates the `example-get-started` DVC project from
  scratch. A source code archive is downloaded from S3 the same way as in
  [Connect Code and Data](https://dvc.org/doc/get-started/connect-code-and-data).

  > If you change the [source code](code/src/) files in this repo, run
  > `deploy.sh` first, to make sure that the `code.zip` archive is up to date.

### example-dvc-experiments

- `generate.sh`: Generates the [repository](https://github.com/iterative/example-dvc-experiments) for _Get Started with Experiments_.  It creates a new project in `example-dvc-experiments/build/YYYY-MM-DD-HH-MM-SS/example-dvc-experiments` and an accompanying script to push the repository to DVC and Git. The generated repository uses `s3://dvc-public/remote/example-dvc-experiments/` as a DVC remote.

### example-studio-all-fashion-mnist

- `generator.sh`: Generates the `fashion-mnist` DVC project from scratch.
    
    Mandatory arguments to `generator.sh` are:
    1. Git account or org name (eg, tapadipti)
    2. Repo name (eg, fashion_mnist)
    3. Git author name (eg, tapadipti)
    4. Git author email (eg, tapadipti@gmail.com)
    5. DVC remote URL (eg, s3://mydvc/tapa)
  
  Eg, `sh generator.sh tapadipti fashion_mnist tapadipti tapadipti@gmail.com s3://mydvc/tapa`
  
  The repo will be created at https://github.com/GIT_ACC_OR_ORG/REPO_NAME (eg, https://github.com/tapadipti/fashion_mnist).
  
  If this repo already exists, it will be replaced by the new one - so make sure that you don't need the existing one.
  
  Make sure you have the required access to the Git account and DVC remote location.