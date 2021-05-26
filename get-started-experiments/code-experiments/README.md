## DVC Get Started for Experiments

This project trains a classifier on [Fashion MNIST][fmnist] dataset in
Tensorflow. 

[fmnist]: https://github.com/zalandoresearch/fashion-mnist

It is used as a showcase for [`dvc exp`][gsdvcexp] commands to manage large
number of experiments. 

[gsdvcexp]: https://dvc.org/doc/start/experiments

After [installing DVC][installdvc] and cloning the repository, you can run:

[installdvc]: https://dvc.org/doc/install

```console
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
```

Retrieve all the required data and model files:

```console
dvc pull
```

`params.yaml` defines many parameters to modify with `dvc exp run --set-param/-S`
option. For example, to set the number of convolutional units in `cnn` model, you
can use:

```console
dvc exp run -S model.cnn.conv_units=128 
```

The experiment will produce a new `metrics.json` and you can check the changes
in metrics:

```console
dvc exp diff
```

You can queue many experiments with `--queue` option:

```console
dvc exp run --queue -S model.cnn.dropout=0.1
dvc exp run --queue -S model.cnn.dropout=0.2
dvc exp run --queue -S model.cnn.dropout=0.3
dvc exp run --queue -S model.cnn.dropout=0.4
dvc exp run --queue -S model.cnn.dropout=0.5
dvc exp run --queue -S model.cnn.dropout=0.6
dvc exp run --queue -S model.cnn.dropout=0.7
dvc exp run --queue -S model.cnn.dropout=0.8
dvc exp run --queue -S model.cnn.dropout=0.9
```

and run them at once, possibly in parallel with `--jobs`:

```console
dvc exp run --run-all --jobs 4
```

You can get the summary of experiments with: 

```console
dvc exp show
```

and limit the parameters and metrics to show with `--include-params` and
`--include-metrics` options, respectively.  

Experiments are given hash-names derived from their inputs and environment. It
may be easier to review them when you give names with the `--name/-n` option.

```console
dvc exp run -n baseline-experiment
```

Experiments are normally not preserved by Git. If you want to do so, you can
use:

```console
dvc exp apply exp-123456
```

Then, you can use `git add`, `git commit`, `git push` and `dvc push` as usual. 

You can push and pull the _code changes_ related to an experiment with `dvc exp
push` and `dvc exp pull` respectively. These two commands work with _Git
remotes._

You can clean up the unused experiments with:

```console
dvc exp gc --workspace
```

### Pipeline and Parameters

The pipeline defined in `dvc.yaml` consists of four stages that depend on each
other sequentially: `prepare`, `preprocess`, `train`, and `evaluate`. The
`train` stage also depends on `src/models.py` that defines two simple models,
`mlp` and `cnn`.

When you change a stage's parameters, all dependent stages are also run by `dvc
exp run`. For example, changing a parameter for `prepare` will result in all
the later stages being run.

<details>
<summary>Parameters</summary>

Notable parameters for each stage that you can use with `--set-param` option are
as follows: 

- `prepare.remix`: Determines whether Fashion-MNIST train (60000 images) and
  test (10000 images) sets are merged and split. If `false`, the test and
  train sets are not merged and used as in the original.
- `prepare.remix_split`: Determines the split ratio between training and testing
  sets if `remix` is `true`. For `0.20`, a total of 70000 images are randomly
  split into 56000 training and 14000 test sets.
- `prepare.seed`: The RNG seed used in shuffling after the remix.
- `preprocess.seed`: The RNG seed used in shuffling. 
- `preprocess.normalize`: If `true`, normalizes the pixel values (0-255)
   dividing by 255.  Although this is a standard and required procedure, you
   may want to observe the effects by turning it off.
- `preprocess.shuffle`: If `true`, shuffles the training and test sets. 
- `preprocess.add_noise`: If `true` adds salt-and-pepper noise by setting some
  pixels to white and some pixels to black. This may be used to reduce
  overfitting.
- `preprocess.noise_amount`: Sets the amount of S&P noise added to the images if
  `add_noise` is `true`.
- `preprocess.noise_s_vs_p`: Sets the ratio of white and black noise in images if
  `add_noise` is `true`.
- `train.validation_split`: The split ratio for the validation set, reserved
  from the training set. If this value is `0`, the test set is used for
  validation. 
- `train.epochs`: Number of epochs to train the network. 
- `train.batch_size`: Batch size for the `model.fit` method. 
- `model.name`: Used to select the model. For `mlp` a simple NN with a single
  hidden layer is used. For `cnn`, a Convolutional Net with a single `Conv2D`
  and a single `Dense` layer is used. The parameters for these networks are defined in separate sections below.
- `model.optimizer`: Can be one of `Adam`, `SGD`, `RMSprop`, `Adadelta`, `Adagrad`, `Adamax`, `Nadam`, `Ftrl`.
- `model.mlp.units`: Number of `Dense` units in MLP.
- `model.mlp.activation`: Activation function for the `Dense` layer. Can be one
  of `relu`, `selu`, `elu`, `tanh`
- `model.cnn.dense_units`: Number of units in `Dense` layer of the CNN.
- `model.cnn.activation`: The activation function for the convolutional layer.
  Can be one of `relu`, `selu`, `elu` or `tanh`.
- `model.cnn.conv_kernel_size`: One side of convolutional kernel, e.g., for
  `3`, a `(3, 3)` convolution applied to the images.
- `model.cnn.conv_units`: Number of convolutional units. 
- `model.cnn.dropout`: Dropout rate between `0` and `1`. 
</details>

### Metrics
<details>

<summary>
The following metrics are produced by `evaluate` stage. You can include or
exclude them in `dvc exp show` with `--include-metrics` and `--exclude-metrics`
options.
</summary>

- `categorical_accuracy`: Produces accuracy metrics for the classes.
- `recall`: Recall metric (True Positives / All Relevant Elements)
- `precision`: Precision metric (True Positives / All Positives)
- `auc-roc`: Generates [Receiver Operating Characteristic][wproc] curve
- `auc-prc`: Generates Precision-Recall Curve
- `fp`: Number of False Positives
- `fn`: Number of False Negatives
- `tp`: Number of True Positives
- `tn`: Number of True Negatives

[wproc]: https://en.wikipedia.org/wiki/Receiver_operating_characteristic
</details>

## Files

### Data Files

The data files used in the project are found in `data/fashion-mnist`. All of
these files are tracked by DVC and can be retrieved using `dvc pull` from the
configured remote.

- `data/fashion-mnist/raw.dvc`: Contains a reference to the [Dataset
  Registry][dsr] to download the Fashion-MNIST dataset to
  `data/fashion-mnist/raw/`.

[dsr]: https://github.com/iterative/dataset-registry

- `data/fashion-mnist/prepared/`: Created by `src/prepare.py` and contains
  training and testing files in NumPy format.

- `data/fashion-mnist/preprocessed/`: Created by `src/preprocess.py` and
  contains training and testing files in NumPy format ready to be supplied to
  `model.train`.

### Source Files

The source files are in the `src/` directory. All files receive runtime
parameters from `params.yaml`, so none of them require any options. Almost all
capabilities of these scripts can be modified with the options in `params.yaml`

- `src/prepare.py`: Reads the raw dataset files from `data/fashion-mnist/raw/`
  in _IDX3_ format and converts to NumPy format. As the MNIST dataset already
  contains train and test sets, this script can remix and split them if needed.
  The output files are stored in `data/fashion-mnist/prepared/`.
  
- `src/preprocess.py`: Reads data files from `data/fashion-mnist/prepared/` and
  adds salt and pepper noise, normalize the values and shuffles. The output in
  `data/fashion-mnist/preprocessed/` is ready to supply to the Neural Network.

- `src/models.py`: Contains two models. The first one is an MLP with a single
  hidden layer.  The second is a deeper network with a convolution layer, max
  pooling, dropout, and a hidden dense layer. Various parameters of these
  networks can be set in `params.yaml`. The metrics produced as the output are
  also compiled into models in this file. 

- `src/train.py`: Trains the specific neural network returned by
 `src/models.py` with the data in `data/fashion-mnist/preprocessed/`. It
 produces `logs.csv` plots file during the training that contains various
 metrics for each epoch, and `models/fashion-mnist/model.h5` file at the end. 

- `src/evaluate.py`: Tests the model `models/model.h5` created by the training
  stage, with the test data in `data/preprocessed`. It produces `metrics.json`
  file containing the performance metrics for the test set.

- `requirements.txt`: Contains the requirements to run the project.
  
### Model Files

- `models/fashion-mnist/model.h5`: The Tensorflow model produced by
  `src/train.py` in HDF5 format.

### Metrics and Plots

Following two files are tracked by DVC as plots and metrics files, respectively.

- `logs.csv`: Training and validation metrics in each epoch produced in
  `src/train.py` is written to this file.

- `metrics.json`: Final metrics produced by the test set is output to this file.
  

## DVC Files

The repository is a standard Git repository and contains the usual `.dvc` files:

- `.dvc/config`: Contains a remote configuration to retrieve dataset from S3.

- `dvc.yaml`: Contains the pipeline configuration.

- `dvc.lock`: Parameters and dependency hashes are tracked with this file.
