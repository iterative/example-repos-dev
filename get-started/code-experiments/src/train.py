import tensorflow as tf
import numpy as np
from util import load_params, load_npz_data, shuffle_in_parallel
import os
import json

import models


def normalize(images_array):
    return images_array / 255


def add_noise(images, s_vs_p=0.5, amount=0.0004):
    n_images, n_row, n_col = images.shape
    out = np.copy(images)
    # Salt mode
    n_salt = np.ceil(amount * images.size * s_vs_p)
    salt_coords = [np.random.randint(0, i - 1, int(n_salt))
                   for i in images.shape]
    out[salt_coords] = 1

    # Pepper mode
    n_pepper = np.ceil(amount * images.size * (1. - s_vs_p))
    pepper_coords = [np.random.randint(0, i - 1, int(n_pepper))
                     for i in images.shape]
    out[pepper_coords] = 0

    return out


def history_to_csv(history):
    keys = list(history.history.keys())
    csv_string = ", ".join(["epoch"] + keys) + "\n"
    list_len = len(history.history[keys[0]])
    for i in range(list_len):
        row = (
            str(i + 1)
            + ", "
            + ", ".join([str(history.history[k][i]) for k in keys])
            + "\n"
        )
        csv_string += row

    return csv_string


def main():
    params = load_params()["train"]
    m = models.get_model()
    m.summary()
    seed = params["seed"]
    input_dir = params["prepared_input_dir"]
    output_dir = params["model_output_dir"]
    training_set_file = os.path.join(input_dir, "train.npz")
    testing_set_file = os.path.join(input_dir, "test.npz")

    training_images, training_labels = load_npz_data(training_set_file)
    testing_images, testing_labels = load_npz_data(testing_set_file)

    if params["normalize"]:
        training_images = normalize(training_images)
        testing_images = normalize(testing_images)

    if params["shuffle"]:
        training_images, training_labels = shuffle_in_parallel(
            seed, training_images, training_labels)
        testing_images, testing_labels = shuffle_in_parallel(
            seed, testing_images, testing_labels)

    training_labels = tf.keras.utils.to_categorical(
        training_labels, num_classes=10, dtype="float32")
    testing_labels = tf.keras.utils.to_categorical(
        testing_labels, num_classes=10, dtype="float32")

    validation_split_index = int(
        (1 - params["validation_split"]) * training_images.shape[0]
    )
    if validation_split_index == training_images.shape[0]:
        x_train = training_images
        x_valid = testing_images
        y_train = training_labels
        y_valid = testing_labels
    else:
        x_train = training_images[:validation_split_index]
        x_valid = training_images[validation_split_index:]
        y_train = training_labels[:validation_split_index]
        y_valid = training_labels[validation_split_index:]

    print(f"x_train: {x_train.shape}")
    print(f"x_valid: {x_valid.shape}")
    print(f"y_train: {y_train.shape}")
    print(f"y_valid: {y_valid.shape}")

    history = m.fit(
        x_train,
        y_train,
        batch_size=params["batch_size"],
        epochs=params["epochs"],
        verbose=1,
        validation_data=(x_valid, y_valid),
    )

    with open("logs.csv", "w") as f:
        f.write(history_to_csv(history))

    model_file = os.path.join(output_dir, "model.h5")
    m.save(model_file)

    metrics_dict = m.evaluate(
        testing_images,
        testing_labels,
        batch_size=params["batch_size"],
        return_dict=True,
    )
    metrics_file = "metrics.json"

    with open(metrics_file, "w") as f:
        f.write(json.dumps(metrics_dict))


if __name__ == "__main__":
    main()
