import tensorflow as tf
import numpy as np
import os

from util import load_params, history_to_csv, history_list_to_csv
import models
from dvc.api import make_checkpoint

MODEL_FILE = "models/model.h5"

class DVCLiveCallback(tf.keras.callbacks.Callback):

    def on_epoch_end(self, epoch, logs=None):
        logs = logs or {}
        for metric, value in logs.items():
            dvclive.log(metric, value)
        dvclive.next_step()


def load_npz_data(filename):
    npzfile = np.load(filename)
    return (npzfile['images'], npzfile['labels'])

def main():
    params = load_params()["train"]
    if params["resume"] and os.path.exists(MODEL_FILE):
        m = tf.keras.models.load_model(MODEL_FILE)
    else:
        m = models.get_model()
    m.summary()

    whole_train_img, whole_train_labels = load_npz_data("data/preprocessed/mnist-train.npz")
    test_img, test_labels = load_npz_data("data/preprocessed/mnist-test.npz")
    validation_split_index = int((1 - params["validation_split"]) * whole_train_img.shape[0])
    if validation_split_index == whole_train_img.shape[0]:
        x_train = whole_train_img
        x_valid = test_img
        y_train = whole_train_labels
        y_valid = test_labels
    else:
        x_train = whole_train_img[:validation_split_index]
        x_valid = whole_train_img[validation_split_index:]
        y_train = whole_train_labels[:validation_split_index]
        y_valid = whole_train_labels[validation_split_index:]

    print(f"x_train: {x_train.shape}")
    print(f"x_valid: {x_valid.shape}")
    print(f"y_train: {y_train.shape}")
    print(f"y_valid: {y_valid.shape}")

    dvclive.init("training_metrics")

    m.fit(x_train,
                    y_train,
                    batch_size = params["batch_size"],
                    epochs = params["epochs"],
                    verbose=1,
                    validation_data = (x_valid, y_valid),
                    callbacks=[DVCLiveCallback()])

    with open("logs.csv", "w") as f:
        f.write(history_to_csv(history))

    m.save(MODEL_FILE)

if __name__ == "__main__":
    main()
