import os

# Set tensorflow logging to minimum
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"  # or any {'0', '1', '2'}
import tensorflow as tf
import numpy as np
from util import load_params, read_labeled_images
import json
from dvclive.keras import DvcLiveCallback


INPUT_DIR = "data/images"
OUTPUT_DIR = "models"

SEED = 20210715

BATCH_SIZE = 128


def get_model(
    dense_units=128, conv_kernel=(3, 3), conv_units=32, dropout=0.5, activation="relu"
):
    model = tf.keras.models.Sequential(
        [
            tf.keras.layers.Reshape(input_shape=(28, 28), target_shape=(28, 28, 1)),
            tf.keras.layers.Conv2D(
                conv_units, kernel_size=conv_kernel, activation=activation
            ),
            tf.keras.layers.MaxPooling2D(pool_size=(2, 2)),
            tf.keras.layers.Dropout(dropout),
            tf.keras.layers.Flatten(),
            tf.keras.layers.Dense(dense_units, activation=activation),
            tf.keras.layers.Dense(10, activation="softmax"),
        ]
    )

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


def main():
    params = load_params()
    m = get_model(conv_units=params["model"]["conv_units"])
    m.summary()

    training_images, training_labels = read_labeled_images(
        os.path.join(INPUT_DIR, "train/")
    )
    testing_images, testing_labels = read_labeled_images(
        os.path.join(INPUT_DIR, "test/")
    )

    assert training_images.shape[0] + testing_images.shape[0] == 70000
    assert training_labels.shape[0] + testing_labels.shape[0] == 70000

    training_images = normalize(training_images)
    testing_images = normalize(testing_images)

    training_labels = tf.keras.utils.to_categorical(
        training_labels, num_classes=10, dtype="float32"
    )
    testing_labels = tf.keras.utils.to_categorical(
        testing_labels, num_classes=10, dtype="float32"
    )

    # We use the test set as validation for simplicity
    x_train = training_images
    x_valid = testing_images
    y_train = training_labels
    y_valid = testing_labels

    m.fit(
        x_train,
        y_train,
        batch_size=BATCH_SIZE,
        epochs=params["train"]["epochs"],
        verbose=1,
        validation_data=(x_valid, y_valid),
        callbacks=[DvcLiveCallback(model_file=f"{OUTPUT_DIR}/model.h5")],
    )

    m.evaluate(
        testing_images,
        testing_labels,
        batch_size=BATCH_SIZE,
        return_dict=True,
    )


if __name__ == "__main__":
    main()
