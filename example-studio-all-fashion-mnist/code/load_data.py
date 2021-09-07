import os, pickle
from tensorflow.keras.datasets import fashion_mnist

data = fashion_mnist.load_data()

OUTPUT_DIR = "output"
fpath = os.path.join(OUTPUT_DIR, "data.pkl")
with open(fpath, "wb") as fd:
    pickle.dump(data, fd)
