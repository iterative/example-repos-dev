from re import A
import struct
import numpy as np
import gzip
import os
from util import load_params
from imageio import imread, mimread


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
    image_array = np.ndarray(shape=(len(images), shape_0, shape_1), dtype='uint8')
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


def mnist_images_idx_to_array(images_filename):
    images_f = gzip.open(images_filename, mode="rb")
    images_f.seek(0)
    magic = struct.unpack('>I', images_f.read(4))[0]
    if magic != 0x00000803:
        raise Exception(f"Format error: Need an IDX3 file: {images_filename}")
    n_images = struct.unpack('>I', images_f.read(4))[0]
    n_row = struct.unpack('>I', images_f.read(4))[0]
    n_col = struct.unpack('>I', images_f.read(4))[0]

    n_bytes = n_images * n_row * n_col  # each pixel is 1 byte

    images_data = struct.unpack(
        '>' + str(n_bytes) + 'B', images_f.read(n_bytes))

    images_array = np.asarray(images_data, dtype='uint8')
    images_array.shape = (n_images, n_row, n_col)

    return images_array


def mnist_labels_idx_to_array(labels_filename):
    labels_f = gzip.open(labels_filename, mode="rb")
    labels_f.seek(0)
    magic = struct.unpack('>I', labels_f.read(4))[0]
    if magic != 0x00000801:
        raise Exception(f"Format error: Need an IDX file: {labels_filename}")
    n_labels = struct.unpack('>I', labels_f.read(4))[0]
    labels_data = struct.unpack(
        '>' + str(n_labels) + 'B', labels_f.read(n_labels))
    labels_array = np.asarray(labels_data, dtype='uint8')
    return labels_array


def remix(images1, images2, labels1, labels2, seed, split):
    images = np.vstack((images1, images2))
    labels = np.hstack((labels1, labels2))

    assert(images.shape[0] == labels.shape[0])

    np.random.seed(seed)
    np.random.shuffle(images)
    np.random.seed(seed)
    np.random.shuffle(labels)

    split_index = int(images.shape[0] * (1 - split))

    images1 = images[:split_index]
    labels1 = labels[:split_index]
    images2 = images[split_index:]
    labels2 = labels[split_index:]

    return (images1, images2, labels1, labels2)


def main():
    params = load_params()["prepare"]
    print(params)

    input_dir = params["images_input_dir"]
    output_dir = params["prepared_output_dir"]

    training_images, training_labels = read_labeled_images(
        os.path.join(input_dir, 'train/'))
    testing_images, testing_labels = read_labeled_images(
        os.path.join(input_dir, 'test/')
    )

    if params["remix"]:
        (training_images,
         testing_images,
         training_labels,
         testing_labels) = remix(images1=training_images,
                                 images2=testing_images,
                                 labels1=training_labels,
                                 labels2=testing_labels,
                                 seed=params["seed"],
                                 split=params["remix_split"])

        assert training_images.shape[0] + testing_images.shape[0] == 70000
        assert training_labels.shape[0] + testing_labels.shape[0] == 70000

    print(f"Training Dataset Shape: {training_images.shape}")
    print(f"Testing Dataset Shape: {testing_images.shape}")
    print(f"Training Labels: {training_labels}")
    print(f"Testing Labels: {testing_labels}")

    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    np.savez(os.path.join(output_dir, "train.npz"),
             images=training_images, labels=training_labels)
    np.savez(os.path.join(output_dir, "test.npz"),
             images=testing_images, labels=testing_labels)


if __name__ == "__main__":
    main()
