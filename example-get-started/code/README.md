# DVC Get Started

This is an auto-generated repository for use in https://dvc.org/doc/get-started.
Please report any issues in
[example-repos-dev](https://github.com/iterative/example-repos-dev).

![](https://dvc.org/static/img/example-flow-2x.png)

_Get Started_ is a step by step introduction into basic DVC concepts. It doesn't
go into details much, but provides links and expandable sections to learn more.

The idea of the project is a simplified version of the
[Tutorial](https://dvc.org/doc/tutorial). It explores the natural language
processing (NLP) problem of predicting tags for a given StackOverflow question.
For example, we want one classifier which can predict a post that is about the
Python language by tagging it `python`.

## Installation

Start by cloning the project:

```console
$ git clone https://github.com/iterative/example-get-started
$ cd example-get-started
```

Now let's install the requirements. But before we do that, we **strongly**
recommend creating a virtual environment with a tool such as
[virtualenv](https://virtualenv.pypa.io/en/stable/):

```console
$ virtualenv -p python3 .env
$ source .env/bin/activate
$ pip install -r src/requirements.txt
```

This DVC project comes with a preconfigured remote DVC storage that has raw data
(input), intermediate, and final results that are produced.

```console
$ dvc remote list
storage https://remote.dvc.org/get-started
```

You can run [`dvc pull`](https://man.dvc.org/pull) to download the data:

```console
$ dvc pull -r storage
```

## Running in Your Environment

Run [`dvc repro`](https://man.dvc.org/repro) to reproduce the
[pipeline](https://dvc.org/doc/commands-reference/pipeline):

```console
$ dvc repro evaluate.dvc
```

> `dvc repro` requires a target [stage file](https://man.dvc.org/run)
> ([DVC-file](https://dvc.org/doc/user-guide/dvc-file-format)) to reconstruct
> and regenerate a pipeline. In this case we use `evaluate.dvc`, the last stage
> in this project's pipeline.

If you'd like to test commands like [`dvc push`](https://man.dvc.org/push),
that require write access to the remote storage, the easiest way would be to set
up a "local remote" on your file system:

> This kind of remote is located in the local file system, but is external to
> the DVC project.

```console
$ mkdir -P /tmp/dvc-storage
$ dvc remote add local /tmp/dvc-storage
```

You should now be able to run:

```console
$ dvc push -r local
```

## Existing Stages

This project with the help of the Git tags reflects the sequence of actions that
are run in the DVC [get started](https://dvc.org/doc/get-started) guide. Feel
free to checkout one of them and play with the DVC commands having the
playground ready.

- `0-empty` - empty Git repository.
- `1-initialize` - DVC has been initialized. The `.dvc` with the cache directory
  created.
- `2-remote` - remote HTTP storage initialized. It is a shared read only storage
  that contains all data artifacts produced during next steps.
- `3-add-file` - raw data file `data.xml` downloaded and put under DVC
  control with [`dvc add`](https://man.dvc.org/add). First `.dvc` meta-file
  created.
- `4-source` - source code downloaded and put under Git control.
- `5-preparation` - first DVC stage created using
  [`dvc run`](https://man.dvc.org/run). It transforms XML data into TSV.
- `6-featurization` - feature extraction step added. It also includes the split
  step for simplicity. It takes data in TSV format and produces two `.pkl` files
  that contain serialized feature matrices.
- `7-train` - the model training stage added. It produces `model.pkl` file - the
  actual result that can be then deployed somewhere and classify questions.
- `8-evaluate` - evaluate stage, we run it on a test dataset to see the AUC
  value for the model. The result is dumped into a DVC metric file so that we
  can compare it with other experiments later.
- `9-bigrams` - bigrams experiment, code has been modified to extract more
  features. We run [`dvc repro`](https://man.dvc.org/repro) for the first time
  to illustrate how DVC can reuse cached files and detect changes along the
  computational graph.

There are two additional tags:

- `baseline-experiment` - the first end-to-end result that we performance metric
  for.
- `bigrams-experiment` - second version of the experiment.

Both these tags could be used to illustrate `-a` or `-T` options across
different [DVC commands](https://man.dvc.org/).

## Project Structure

The data files, DVC-files, and results change as stages are created one by one,
but right after you for Git clone and [`dvc pull`](https://man.dvc.org/pull) to
download files that are under DVC control, the structure of the project should
look like this:

```sh
$ tree
.
├── auc.metric            # <-- DVC metric compares baseline and bigrams
├── data                  # <-- Directory with raw and intermediate data
│   ├── features          # <-- Extracted feature matrices
│   │   ├── test.pkl
│   │   └── train.pkl
│   └── prepared          # <-- Processed dataset (split and TSV formatted)
│       ├── test.tsv
│       └── train.tsv
│   ├── data.xml          # <-- Initial XML StackOverflow dataset (raw data)
│   ├── data.xml.dvc
├── evaluate.dvc          # <-- DVC-files in the project root describe pipeline
├── featurize.dvc
├── model.pkl
├── prepare.dvc
├── src                   # <-- Source code to run the pipeline stages
│   ├── evaluate.py
│   ├── featurization.py
│   ├── prepare.py
│   └── train.py
│   └── requirements.txt  # <-- Python dependencies needed in the project
└── train.dvc
```
