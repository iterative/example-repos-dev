import tensorflow as tf
import numpy as np
from util import load_params, read_labeled_images
import os
import json

INPUT_DIR = "data/images"
RESUME_PREVIOUS_MODEL = False
OUTPUT_DIR = "models"

METRICS_FILE = "metrics.json"
SEED = 20210715

BATCH_SIZE = 128


def get_model(dense_units=128,
              conv_kernel=(3, 3),
              conv_units=32,
              dropout=0.5,
              activation="relu"):
    model = tf.keras.models.Sequential([
        tf.keras.layers.Reshape(input_shape=(28, 28),
                                target_shape=(28, 28, 1)),
        tf.keras.layers.Conv2D(conv_units,
                               kernel_size=conv_kernel,
                               activation=activation),
        tf.keras.layers.MaxPooling2D(pool_size=(2, 2)),
        tf.keras.layers.Dropout(dropout),
        tf.keras.layers.Flatten(),
        tf.keras.layers.Dense(dense_units, activation=activation),
        tf.keras.layers.Dense(10, activation="softmax")])

    loss = tf.keras.losses.CategoricalCrossentropy()
    metrics = [tf.keras.metrics.CategoricalAccuracy(name="acc")]
    optimizer = "Adam"
    model.compile(
        optimizer=optimizer,
        loss=loss,
        metrics=metrics,
    )

    return model


def normalize(images_array):
    return images_array / 255


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
    params = load_params()
    m = get_model()
    m.summary()

    training_images, training_labels = read_labeled_images(
        os.path.join(INPUT_DIR, 'train/'))
    testing_images, testing_labels = read_labeled_images(
        os.path.join(INPUT_DIR, 'test/')
    )

    assert training_images.shape[0] + testing_images.shape[0] == 70000
    assert training_labels.shape[0] + testing_labels.shape[0] == 70000

    print(f"Training Dataset Shape: {training_images.shape}")
    print(f"Testing Dataset Shape: {testing_images.shape}")
    print(f"Training Labels: {training_labels}")
    print(f"Testing Labels: {testing_labels}")

    training_images = normalize(training_images)
    testing_images = normalize(testing_images)

    training_labels = tf.keras.utils.to_categorical(
        training_labels, num_classes=10, dtype="float32")
    testing_labels = tf.keras.utils.to_categorical(
        testing_labels, num_classes=10, dtype="float32")

    # We use the test set as validation for simplicity
    x_train = training_images
    x_valid = testing_images
    y_train = training_labels
    y_valid = testing_labels

    history = m.fit(
        x_train,
        y_train,
        batch_size=BATCH_SIZE,
        epochs=params["train"]["epochs"],
        verbose=1,
        validation_data=(x_valid, y_valid),
    )

    with open("logs.csv", "w") as f:
        f.write(history_to_csv(history))

    model_file = os.path.join(OUTPUT_DIR, "model.h5")
    m.save(model_file)

    metrics_dict = m.evaluate(
        testing_images,
        testing_labels,
        batch_size=BATCH_SIZE,
        return_dict=True,
    )

    with open(METRICS_FILE, "w") as f:
        f.write(json.dumps(metrics_dict))


if __name__ == "__main__":
    main()
