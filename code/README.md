# DVC Get Started

This is an auto-generated repository (please, don't create issues here, use the
[example-get-started-dev](https://github.com/iterative/example-get-started-dev)).

![](https://dvc.org/static/img/example-flow-2x.png)

The idea of the project is a simplified version of the
[tutorial](https://dvc.org/doc/tutorial). It explores the natural language
processing (NLP) problem of predicting tags for a given StackOverflow question.
For example, we want one classifier which can predict a post that is about the
Python language by tagging it `python`.

## Installation

First, you need to download the project:

```shell
    $ git clone https://github.com/iterative/example-get-started
```

Second, let's install the requirements. But before we do that, we **strongly**
recommend creating a virtual environment with `virtualenv` or a similar tool:

```shell
    $ cd example-get-started
    $ virtualenv -p python3 .env
    $ source .env/bin/activate
```

Now, we can install requirements for the project:

```shell
    $ pip install -r requirements.txt
```

## Running in Your Environment

This project comes with a predefined remote DVC storage that contains all input,
intermediate and final results that were produced.

```shell
    $ dvc remote list
    storage https://remote.dvc.org/get-started
```

You can run [`dvc pull`](https://man.dvc.org/pull) to download the data:

```shell
    $ dvc pull -r storage
```

and [`dvc repro`](https://man.dvc.org/repro) to reproduce the pipeline:

```shell
    $ dvc repro evaluate.dvc
```

If you'd like to test commands like [`dvc push`](https://man.dvc.org/push),
that require write access to the remote storage, the easiest way would be to set
up the local remote on your file system:

```shell
    $ dvc remote add local /tmp/dvc-storage
```

You should be able to run:

```shell
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
- `3-add-file` - input data file `data.xml` downloaded and put under DVC
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

Both these tags could be used to illustrate `-a` or `-T` DVC options across
different commands.

## Project Structure

The project files, DVC files, data files changes as you apply stages one by one,
but right after you for Git clone and [`dvc pull`](https://man.dvc.org/pull) to
download files that are under DVC control, the structure of the project should
look like this:

```shell
    .
    ├── auc.metric           <-- DVC metric file to compare baseline and bigrams
    ├── data                 <-- directory with input and intermediate data
    │   ├── features         <-- extracted feature matrices
    │   │   ├── test.pkl
    │   │   └── train.pkl
    │   └── prepared         <-- pre-processed dataset, split and TSV formatted
    │       ├── test.tsv
    │       └── train.tsv
    │   ├── data.xml         <-- initial XML StackOverflow dataset
    │   ├── data.xml.dvc
    ├── evaluate.dvc         <-- DVC files in the project root describe pipeline
    ├── featurize.dvc
    ├── model.pkl
    ├── prepare.dvc
    ├── requirements.txt     <-- Python dependencies you need to run the project
    ├── src                  <-- sources to run the pipeline
    │   ├── evaluate.py
    │   ├── featurization.py
    │   ├── prepare.py
    │   └── train.py
    └── train.dvc
```

