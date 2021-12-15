import os
# Set tensorflow logging to minimum
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # or any {'0', '1', '2'}
import tensorflow as tf
import numpy as np
from util import load_params, read_labeled_images
import json
import tarfile
import imageio

DATASET_FILE = "data/images.tar.gz"
OUTPUT_DIR = "models"

METRICS_FILE = "metrics.json"
SEED = 20210715

BATCH_SIZE = 128


def label_from_path(filepath):
    """extracts "test", and 3 from a path like "images/test/3/00177.png" """
    elements = filepath.split('/')
    return (elements[1], int(elements[2]))

def read_dataset(dataset_path):
    ds = tarfile.open(name=dataset_path, mode='r:gz')
    training, testing = [], []
    print(f"Reading dataset from {dataset_path}")
    for f in ds:
        if f.isfile():
            filepath = f.name
            content = ds.extractfile(f)
            image = imageio.imread(content)
            imagesection, imagelabel = label_from_path(filepath)
            if imagesection == "train":
                training.append((imagelabel, image))
            else:
                testing.append((imagelabel, image))

    print(f"Read {training.len()} training images and {testing.len()} testing images")
    # we assume the images are 28x28 grayscale
    shape_0, shape_1 = 28, 28
    testing_images = np.ndarray(shape=(len(testing), shape_0, shape_1), dtype="uint8")
    testing_labels = np.zeros(shape=(len(testing)), dtype="uint8")
    for i, (label, image) in enumerate(testing):
        testing_images[i] = image
        testing_labels[i] = label
    training_images = np.ndarray(shape=(len(training), shape_0, shape_1), dtype="uint8")
    training_labels = np.zeros(shape=(len(training)), dtype="uint8")
    for i, (label, image) in enumerate(training):
        training_images[i] = image
        training_labels[i] = label
    return (training_images, training_labels, testing_images, testing_labels)


def create_image_matrix(cells):
    """cells is a dictionary containing 28x28 arrays for each (i, j) key. These are printed on a max(i) * 30 x max(j) * 30 array."""

    max_i, max_j = 0, 0
    for (i, j) in cells:
        if i > max_i:
            max_i = i
        if j > max_j:
            max_j = j

    frame_size = 30
    image_shape = (28, 28)

    out_matrix = np.ones(shape=(max_i * frame_size, max_j * frame_size), dtype="uint8") * 255

    for (i, j) in cells:
        image = cells[(i, j)]
        assert image.shape == image_shape
        xs = i * frame_size + 1
        xe = (i + 1) * frame_size - 1
        ys = j * frame_size + 1
        ye = (j + 1) * frame_size - 1
        out_matrix[xs:xe, ys:ye] = image

    return out_matrix

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

    # predictions for the confusion matrix
    y_prob = m.predict(x_valid)
    y_pred = y_prob.argmax(axis=-1)
    os.makedirs("plots")
    with open("plots/confusion.csv", "w") as f:
        f.write("actual,predicted\n")
        sx = y_valid.shape[0]
        for i in range(sx):
            f.write(f"{y_valid.argmax()},{y_pred[i]}\n")


if __name__ == "__main__":
    main()
