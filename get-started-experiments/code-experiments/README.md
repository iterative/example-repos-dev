## DVC Get Started with Experiments

This project trains a classifier on [Fashion
MNIST](https://github.com/zalandoresearch/fashion-mnist) dataset in Tensorflow. 

It is used as a showcase for [`dvc exp`](https://dvc.org/doc/start/experiments)
commands to manage large number of experiments. 

<details>

<summary>
### Installation Instructions
</summary>

After [installing DVC](https://dvc.org/doc/install) and cloning the repository, you can run:

```console
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
```

Retrieve all the required data and model files:

```console
dvc pull
```
</details>

## Running Experiments

You can run the experiment defined in the project.

```console
dvc exp run
```

This new command in DVC 2.0 also allows to change the parameters on the fly with `--set-param` option. 

```console
dvc exp run --set-param conv_units=128 
```

`params.yaml` defines four parameters to modify with `dvc exp run
--set-param/-S` option. The above command updates `params.yaml` with
`conv_units: 128` before running the experiment. 

The experiment will produce a new `metrics.json` and you can check the changes
in metrics:

```console
dvc exp diff
```

It's also possible to queue experiments with `--queue` option and run them all
in a single batch with `--run-all`.

```console
dvc exp run --queue -S dropout=0.3
dvc exp run --queue -S dropout=0.6
dvc exp run --queue -S dropout=0.9
```

The experiments can also be run in parallel with `--jobs`.

```console
dvc exp run --run-all --jobs 2
```

You can get the summary of experiments with: 

```console
dvc exp show
```

Limit the parameters and metrics to show with `--include-params` and
`--include-metrics` options, respectively.  

By default experiments are given auto-generated names derived from their inputs
and environment. It may be easier to review them when you give names with the
`--name/-n` option.

```console
dvc exp run -n baseline-experiment
```

Artifacts produced by experiments are normally not preserved in the repository.
If you want to do so, you can use:

```console
dvc exp apply exp-123456
```

where `exp-123456` is the experiment ID you see with `dvc exp show`. 

Then, you can use `git add`, `git commit`, `git push` and `dvc push` as usual. 

You can push and pull the _code changes_ related to an experiment with `dvc exp
push` and `dvc exp pull` respectively. These two commands work with _Git
remotes._

You can clean up the unused experiments with:

```console
dvc exp gc --workspace
```

### Parameters

Although the project has several parameters that can be changed from the code,
we kept the number of parameters in `params.yaml` low for illustration
purposes. 

Parameters and their default values are as follows.

```yaml
epochs: 1
conv_units: 16
dense_units: 128
dropout: 0.5
```

The first of these parameters is the number of training epochs, and the rest
define the CNN model's structure. 

### Metrics

There are two metrics produced by the training stage. 

- `loss`: Categorical Crosstentropy loss value 
- `acc`: Categorical Accuracy metrics for the classes.

### Pipeline 

The pipeline defined in `dvc.yaml` consists of two stages: `prepare` and
`train`. Prepare stage depends to imported Fashion-MNIST data found in
`data/raw`, and the train stage depends on `data/prepared` and `models.py`. The
former outputs the data in NumPy format and the latter consumes this, and
produces the model and metrics. 

### Data Files

The data files used in the project are found in `data/`. All of these files are
tracked by DVC and should be retrieved using `dvc pull` from the configured
remote.

- `data/raw.dvc`: Contains a reference to the [Dataset
  Registry](https://github.com/iterative/dataset-registry) to download the
  Fashion-MNIST dataset to `data/raw/`.

- `data/prepared/`: Created by `src/prepare.py` and contains
  training and testing files in NumPy format.

### Source Files

The source files are in the `src/` directory. 

- `src/prepare.py`: Reads the raw dataset files from `data/raw/`
  in _IDX3_ format and converts to NumPy format. The output files are stored in
  `data/prepared/`.
  
- `src/models.py`: Contains Neural Network models defined in Keras.  The one we
  use in the experiments is a CNN with a single convolution layer, max pooling,
  dropout, and a hidden dense layer. Various parameters of these networks can
  be set in `params.yaml`. The metrics produced as the output are also compiled
  into models in this file. 

- `src/train.py`: Trains the specific neural network returned by
 `src/models.py` with the data in `data/prepared/`. It produces `logs.csv`
 plots file during the training that contains various metrics for each epoch,
 and `models/model.h5` file at the end. This script also tests the model with
 the testing data and writes final metrics in `metrics.json`.

- `requirements.txt`: Contains the requirements to run the project.
  
### Model Files

- `models/model.h5`: The Tensorflow model produced by
  `src/train.py` in HDF5 format.

## Contributing

This repository is generated by
[`example-repos-dev`](https://github.com/iterative/example-repos-dev). For Pull
Requests regarding the fixes, please use that repository. 
