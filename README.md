# Get Started Tutorial (sources)

Contains source code, deployment and generation scripts for example DVC
repositories used in the [Get Started](https://dvc.org/doc/get-started) and
other sections of the docs.

- `get-started.sh` - generates the `example-get-started` DVC project from
  scratch. Code bundle is downloaded from S3 the same way as in the _Get
  Started_ -> [Connect Code and
  Data](https://dvc.org/doc/get-started/connect-code-and-data) chapter.

  If you change [source code](code/src/) files, run `deploy.sh` first to make
  sure that the code.zip archive is up to date.

- `deploy.sh` - deploys code archive that is downloaded as part of the
  `get-started.sh` to S3.
  > Requires AWS CLI and write access to `dvc-share` S3 bucket.
