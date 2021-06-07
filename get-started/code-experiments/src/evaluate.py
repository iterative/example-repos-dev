import tensorflow as tf
import numpy as np
import json
from util import load_params, load_npz_data
import os


def main():
    params = load_params()

    test_img, test_labels = load_npz_data(
        os.path.join(params["preprocess"]["preprocessed_output_dir"],
                     "test.npz")
    )
    model = tf.keras.models.load_model(os.path.join(params["train"]["model_output_dir"],
                                                    "model.h5"))

    metrics_dict = model.evaluate(
        test_img,
        test_labels,
        batch_size=params["train"]["batch_size"],
        return_dict=True,
    )
    metrics_file = "metrics.json"

    with open(metrics_file, "w") as f:
        f.write(json.dumps(metrics_dict))


if __name__ == "__main__":
    main()
