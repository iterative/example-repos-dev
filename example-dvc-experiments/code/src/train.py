import os
# Set tensorflow logging to minimum
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # or any {'0', '1', '2'}
import tensorflow as tf
import numpy as np
from util import load_params, read_labeled_images, label_from_path, read_dataset, create_image_matrix
import json
import tarfile
import imageio
from dvclive.keras import DvcLiveCallback

DATASET_FILE = "data/images.tar.gz"
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
    m = get_model(conv_units=params['model']['conv_units'])
    m.summary()

    training_images, training_labels, testing_images, testing_labels = read_dataset(DATASET_FILE)

    assert training_images.shape[0] + testing_images.shape[0] == 70000
    assert training_labels.shape[0] + testing_labels.shape[0] == 70000

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
        callbacks=[DvcLiveCallback(model_file=f"{OUTPUT_DIR}/model.h5")],
    )

    metrics_dict = m.evaluate(
        testing_images,
        testing_labels,
        batch_size=BATCH_SIZE,
        return_dict=True,
    )

    with open(METRICS_FILE, "w") as f:
        f.write(json.dumps(metrics_dict))

    misclassified = {}

    # predictions for the confusion matrix
    y_prob = m.predict(x_valid)
    y_pred = y_prob.argmax(axis=-1)
    os.makedirs("plots")
    with open("plots/confusion.csv", "w") as f:
        f.write("actual,predicted\n")
        sx = y_valid.shape[0]
        for i in range(sx):
            actual=y_valid[i].argmax()
            predicted=y_pred[i]
            f.write(f"{actual},{predicted}\n")
            misclassified[(actual, predicted)] = x_valid[i]


    # find misclassified examples and generate a confusion table image
    confusion_out = create_image_matrix(misclassified)
    imageio.imwrite("plots/confusion.png", confusion_out)

if __name__ == "__main__":
    main()
