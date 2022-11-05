import os

import numpy as np
import tarfile
from imageio import imread
from ruamel.yaml import YAML

def label_from_path(filepath):
    """extracts "test", and 3 from a path like "images/test/3/00177.png" """
    elements = filepath.split('/')
    return (elements[1], int(elements[2]))

def read_dataset(dataset_path):
    """Reads the dataset from the specified tar.gz file and returns 4-tuple of
    numpy arrays (training_images, training_labels, testing_images,
    testing_labels)"""
    ds = tarfile.open(name=dataset_path, mode='r:gz')
    training, testing = [], []
    print(f"Reading dataset from {dataset_path}")
    for f in ds:
        if f.isfile():
            filepath = f.name
            content = ds.extractfile(f)
            image = imread(content)
            imagesection, imagelabel = label_from_path(filepath)
            if imagesection == "train":
                training.append((imagelabel, image))
            else:
                testing.append((imagelabel, image))
    training_len = len(training)
    testing_len = len(testing)
    print(f"Read {training_len} training images and {testing_len} testing images")
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
    """cells is a dictionary containing 28x28 arrays for each (i, j) key. These
    are printed on a max(i) * 30 x max(j) * 30 numpy uint8 array with 3
    channels."""

    max_i, max_j = 0, 0
    for (i, j) in cells:
        if i > max_i:
            max_i = i
        if j > max_j:
            max_j = j

    frame_size = 30
    image_shape = (28, 28)
    incorrect_color = np.array((255, 100, 100), dtype="uint8")
    label_color = np.array((100, 100, 240), dtype="uint8")

    # out_matrix contains examples in the axes

    out_matrix = np.ones(shape=((max_i+2) * frame_size, (max_j+2) * frame_size, 3), dtype="uint8") * 240
    print(f"out_matrix: {out_matrix.shape}")

    ## put axis labels

    for i in range(max_i+1):
        if (i, i) in cells:
            image = cells[(i, i)]
            xs = (i + 1) * frame_size + 1
            xe = (i + 2) * frame_size - 1
            ys = 1
            ye = frame_size - 1
            for c in range(3):
                out_matrix[xs:xe, ys:ye, c] = (1 - image) * label_color[c]
                out_matrix[ys:ye, xs:xe, c] = (1 - image) * label_color[c]

    for (i, j) in cells:
        image = cells[(i, j)]
        assert image.shape == image_shape
        xs = (i + 1) * frame_size + 1
        xe = (i + 2) * frame_size - 1
        ys = (j + 1) * frame_size + 1
        ye = (j + 2) * frame_size - 1
        assert (xe-xs, ye-ys) == image_shape
        print((i, j, xs, xe, ys, ye))
        print(out_matrix[xs:xe, ys:ye, :].shape)
        ## I'm sure there is an easier way to broadcast but I'll find it later
        if i != j:
            for c in range(3):
                out_matrix[xs:xe, ys:ye, c] = (1 - image) * incorrect_color[c]

    return out_matrix


def get_images_from_directory(directory):
    image_file_extensions = [".png", ".jpg", ".bmp"]
    images = []
    # we assume the images are 28x28 grayscale
    shape_0, shape_1 = 28, 28
    for f in os.listdir(directory):
        if os.path.splitext(f)[1] in image_file_extensions:
            current_img = imread(os.path.join(directory, f))
            if (
                len(current_img.shape) != 2
                or current_img.shape[0] != shape_0
                or current_img.shape[1] != shape_1
            ):
                raise Exception("Works with 28x28 grayscale images")
            images.append(current_img)
    image_array = np.ndarray(shape=(len(images), shape_0, shape_1), dtype="uint8")
    for i, img in enumerate(images):
        image_array[i] = img
    return image_array


def read_labeled_images(directory):
    """The structure of the directory should be like:
    .
    ├── 0
    ├── 1
    ├── 2
    ├── 3
    ├── 4
    ├── 5
    ├── 6
    ├── 7
    ├── 8
    └── 9

        and contain PNG images in each directory."""
    shape_0, shape_1 = 28, 28
    label_array = np.ndarray(shape=0, dtype="uint8")
    image_array = np.ndarray(shape=(0, shape_0, shape_1), dtype="uint8")
    for label in range(0, 10):
        images_dir = f"{directory}/{label}"
        images = get_images_from_directory(images_dir)
        labels = np.ones(shape=(images.shape[0]), dtype="uint8") * label
        image_array = np.concatenate((image_array, images), axis=0)
        label_array = np.concatenate((label_array, labels), axis=0)

    return image_array, label_array


def load_params():
    "Updates FULL_PARAMS with the values in params.yaml and returns all as a dictionary"
    yaml = YAML(typ="safe")
    with open("params.yaml") as f:
        params = yaml.load(f)
    return params


def load_npz_data(filename):
    npzfile = np.load(filename)
    return (npzfile["images"], npzfile["labels"])


def shuffle_in_parallel(seed, array1, array2):
    np.random.seed(seed)
    np.random.shuffle(array1)
    np.random.seed(seed)
    np.random.shuffle(array2)

    return array1, array2
