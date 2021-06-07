import struct
import numpy as np
import gzip
import os
from util import load_params


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

    input_dir = params["raw_input_dir"]
    output_dir = params["prepared_output_dir"]

    training_images = mnist_images_idx_to_array(
        os.path.join(input_dir, "train-images-idx3-ubyte.gz"))
    training_labels = mnist_labels_idx_to_array(
        os.path.join(input_dir, "train-labels-idx1-ubyte.gz"))
    testing_images = mnist_images_idx_to_array(
        os.path.join(input_dir, "t10k-images-idx3-ubyte.gz"))
    testing_labels = mnist_labels_idx_to_array(
        os.path.join(input_dir, "t10k-labels-idx1-ubyte.gz"))

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
