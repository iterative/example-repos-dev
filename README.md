# Get Started Tutorial (sources)

Contains source code, deployment and generation scripts for the
[get started](https://dvc.org/doc/get-started) tutorial.

- `create.sh` - generates the `example-get-started` repository. The previous
  version must be manually deleted on Github. Code bundle is downloaded from
  S3 the same way as in the online tutorial. If you update code, make sure
  to run `deploy.sh` first to make sure that the archive is up to date.
- `deploy.sh` - deploys code archive that is downloaded as part of the tutorial
  to S3.

