# Get Started Tutorial (sources)

Contains source code and [Shell](https://www.shellscript.sh/) scripts to
generate and deploy example DVC repositories used in the [Get
Started](https://dvc.org/doc/get-started) and other sections of the DVC docs.

## Requirements

Please make sure you have these available on the environment where these scripts
will run:

- Git
- Python (with `pip`)

## Scripts

Each example DVC project is in each of the root directories (below). `cd` into
the directory first before running the desired script e.g.:

```console
$ cd example-get-started
$ ./deploy.sh
...
```

<!-- ### dataset-registry -->

### example-get-started

- `generate.sh` - generates the `example-get-started` DVC project from
  scratch. A source code archive is downloaded from S3 the same way as in
  [Connect Code and Data](https://dvc.org/doc/get-started/connect-code-and-data).

  > If you change the [source code](code/src/) files in this repo, run
  > `deploy.sh` first, to make sure that the `code.zip` archive is up to date.

- `deploy.sh` - deploys code archive that is downloaded as part of the
  `generate.sh` to S3.
  > Requires AWS CLI and write access to `s3://dvc-public/code/get-started/`.
