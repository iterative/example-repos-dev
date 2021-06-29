from ruamel.yaml import YAML
import numpy as np

FULL_PARAMS = {
    "prepare": {
        "seed": 20210428,
        "remix": False,
        "remix_split": 0.20,
        "images_input_dir": "data/images",
        "prepared_output_dir": "data/prepared"
    },
    "train": {
        "seed": 20210428,
        "validation_split": 0,
        "epochs": 10,
        "batch_size": 128,
        "normalize": True,
        "shuffle": False,
        "add_noise": False,
        "noise_amount": 0.0004,
        "noise_s_vs_p": 0.5,
        "resume": True,
        "prepared_input_dir": "data/prepared",
        "model_output_dir": "models"
    },
    "model":
    {
        "name": "cnn",
        "optimizer": "Adam",
        "mlp": {
            "units": 16,
            "activation": "relu",
        },
        "cnn": {
            "dense_units": 128,
            "activation": "relu",
            "conv_kernel_size": 3,
            "conv_units": 16,
            "dropout": 0.5
        },
        "metrics": {
            "acc": True,
            "precision": False,
            "recall": False,
            "roc": False,
            "pr": False,
            "tp": False,
            "tn": False,
            "fp": False,
            "fn": False
        }
    }
}


def update_param_values(current, update):
    """Updates the values in current with the values in update if they have the
    identical keys.

    This is error prone for dictionary values in update, but we want to use
    flat parameter lists.
    """

    for k, v in current.items():
        if isinstance(v, dict):
            current[k] = update_param_values(v, update)
        elif k in update:
            current[k] = update[k]
    return current


def load_params():
    "Updates FULL_PARAMS with the values in params.yaml and returns all as a dictionary"
    yaml = YAML(typ="safe")
    with open("params.yaml") as f:
        loaded_params = yaml.load(f)
    params = update_param_values(FULL_PARAMS, loaded_params)
    return params


def load_npz_data(filename):
    npzfile = np.load(filename)
    return (npzfile['images'], npzfile['labels'])


def shuffle_in_parallel(seed, array1, array2):
    np.random.seed(seed)
    np.random.shuffle(array1)
    np.random.seed(seed)
    np.random.shuffle(array2)

    return array1, array2
