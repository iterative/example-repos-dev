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

There are 2 GitHub Actions set up to test and deploy the project:

- [test](.github/workflows/example-get-started-test.yaml)
- [deploy](.github/workflows/example-get-started-deploy.yaml)

These will automatically test and deploy the project. If you need to run the project
locally/manually, you only directly need `generate.sh`. `deploy.sh` is a helper script
run within `generate.sh`.

- `generate.sh`: Generates the `example-get-started` DVC project from
  scratch. 

  By default, the source code archive is derived from the local workspace for
  development purposes.

  For deployment, use `generate.sh prod` to upload/download a source code
  archive from S3 the same way as in [Connect Code and
  Data](https://dvc.org/doc/get-started/connect-code-and-data).

- `deploy.sh`: Makes and deploys code archive from
  [example-get-started/code](example-get-started/code) to use for `generate.sh`.

  By default, makes local code archive in example-get-started/code.zip.

  For deployment, use `deploy.sh prod` to upload to S3.

  > Requires AWS CLI and write access to `s3://dvc-public/code/get-started/`.

### example-get-started-experiments

There are 2 GitHub Actions set up to test and deploy the project:

- [test](.github/workflows/example-get-started-experiments-test.yaml)
- [deploy](.github/workflows/example-get-started-experiments-deploy.yaml)

These will automatically test and deploy the project. If you need to run the project locally/manually, run `generate.sh`.

Even after automatic deployment, you still need to follow the
[instructions](example-get-started-experiments/README.md) to:
- Update Studio to create a PR from the best generated experiment.
- Push to GitLab if you want to update the repo there.
