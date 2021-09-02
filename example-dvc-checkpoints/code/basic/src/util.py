from ruamel.yaml import YAML
import numpy as np
import os
from imageio import imread


def get_images_from_directory(directory):
    image_file_extensions = ['.png', '.jpg', '.bmp']
    images = []
    # we assume the images are 28x28 grayscale
    shape_0, shape_1 = 28, 28
    for f in os.listdir(directory):
        if os.path.splitext(f)[1] in image_file_extensions:
            current_img = imread(os.path.join(directory, f))
            if (len(current_img.shape) != 2 or current_img.shape[0] != shape_0 or current_img.shape[1] != shape_1):
                raise Exception("Works with 28x28 grayscale images")
            images.append(current_img)
    image_array = np.ndarray(
        shape=(len(images), shape_0, shape_1), dtype='uint8')
    for i, img in enumerate(images):
        image_array[i] = img
    print(image_array.shape)
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

    and contain PNG images in each directory.
"""
    shape_0, shape_1 = 28, 28
    label_array = np.ndarray(shape=0, dtype='uint8')
    image_array = np.ndarray(shape=(0, shape_0, shape_1), dtype='uint8')
    for label in range(0, 10):
        images_dir = f"{directory}/{label}"
        images = get_images_from_directory(images_dir)
        labels = np.ones(shape=(images.shape[0]), dtype='uint8') * label
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
    return (npzfile['images'], npzfile['labels'])


def shuffle_in_parallel(seed, array1, array2):
    np.random.seed(seed)
    np.random.shuffle(array1)
    np.random.seed(seed)
    np.random.shuffle(array2)

    return array1, array2
