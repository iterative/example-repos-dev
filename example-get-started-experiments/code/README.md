
# DVC Get Started

This is an auto-generated repository for use in [DVC](https://dvc.org)
[Get Started](https://dvc.org/doc/get-started). It is a step-by-step
introduction to basic DVC concepts.

This is a Computer Vision (CV) project that solves the problem of segmenting out swimming pools 
from satellite images. We use a slightly modified version of the 
[BH-Pools dataset](http://patreo.dcc.ufmg.br/2020/07/29/bh-pools-watertanks-datasets/):
we split the original 4k images into tiles of 1024x1024 pixels.


🐛 Please report any issues found in this project here -
[dvc-get-started-cv](https://github.com/iterative/dvc-get-started-cv).

## Installation

Python 3.8+ is required to run code from this repo.

```console
$ git clone https://github.com/iterative/example-get-started-cv
$ cd example-get-started-cv
```

Now let's install the requirements. But before we do that, we **strongly**
recommend creating a virtual environment with a tool such as
[virtualenv](https://virtualenv.pypa.io/en/stable/):

```console
$ python -m venv .venv
$ source .venv/bin/activate
$ pip install -r src/requirements.txt
```

This DVC project comes with a preconfigured DVC
[remote storage](https://dvc.org/doc/commands-reference/remote) that holds raw
data (input), intermediate, and final results that are produced. This is a
read-only HTTP remote.

```console
$ dvc remote list
public_storage  https://remote.dvc.org/get-started-pools
```

You can run [`dvc pull`](https://man.dvc.org/pull) to download the data:

```console
$ dvc pull
```

## Running in your environment

Run [`dvc exp run`](https://man.dvc.org/exp/run) to reproduce the
[pipeline](https://dvc.org/doc/user-guide/pipelines/defining-pipelinese):

```console
$ dvc exp run
Data and pipelines are up to date.
```

If you'd like to test commands like [`dvc push`](https://man.dvc.org/push),
that require write access to the remote storage, the easiest way would be to set
up a "local remote" on your file system:

> This kind of remote is located in the local file system, but is external to
> the DVC project.

```console
$ mkdir -p /tmp/dvc-storage
$ dvc remote add local /tmp/dvc-storage
```

You should now be able to run:

```console
$ dvc push -r local
```

## Existing stages

There is a couple of git tags in this project 

- `1-notebook-dvclive`: Repository with an end-to-end Jupyter notebook that loads data, trains model and reports model performance. [DVCLive](https://dvc.org/doc/] is used for experiment tracking. See this [blog post](https://iterative.ai/blog/exp-tracking-dvc-python) for more details.
- `2-dvc-pipeline`: Contains DVC pipeline `dvc.yaml` that was created by refactoring the above notebook into individual pipeline stages. The pipeline artifacts (processed data, model file, etc) are automatically versioned. This tag also contains a GitHub Actions workflow that reruns the pipeline if any changes are introduced to the pipeline-related files. [CML](https://cml.dev/) is used in this workflow to provision a cloud-based GPU machine as well as report model performance results in Pull Requests.

## Project structure

The data files, DVC files, and results change as stages are created one by one.
After cloning and using [`dvc pull`](https://man.dvc.org/pull) to download
data, models, and plots tracked by DVC, the workspace should look like this:

```console
$ tree -L 2
.
├── LICENSE
├── README.md
├── data.            # <-- Directory with raw and intermediate data
│   ├── pool_data    # <-- Raw image data
│   ├── pool_data.dvc # <-- .dvc file - a placeholder/pointer to raw data
│   ├── test_data    # <-- Processed test data
│   └── train_data   # <-- Processed train data
├── dvc.lock
├── dvc.yaml.        # <-- DVC pipeline file
├── models
│   └── model.pkl    # <-- Trained model file
├── notebooks
│   └── TrainSegModel.ipynb # <-- Initial e2e notebook (later refactored into `dvc.yaml`) 
├── params.yaml      # <-- Parameters file
├── requirements.txt # <-- Python dependencies needed in the project
├── results          # <-- DVCLive reports and plots
│   ├── evaluate
│   └── train
└── src              # <-- Source code to run the pipeline stages
    ├── data_split.py
    ├── evaluate.py
    └── train.py
```
