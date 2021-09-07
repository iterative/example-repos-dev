import numpy as np
import tensorflow, os, json, pickle, yaml
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Conv2D, Flatten, MaxPooling2D
from tensorflow.keras.utils import to_categorical

OUTPUT_DIR = "output"
fpath = os.path.join(OUTPUT_DIR, "data.pkl")
with open(fpath, "rb") as fd:
    data = pickle.load(fd)
(x_train, y_train),(x_test, y_test) = data
    
unique, counts = np.unique(y_train, return_counts=True)
print("Train labels: ", dict(zip(unique, counts)))
unique, counts = np.unique(y_test, return_counts=True)
print("\nTest labels: ", dict(zip(unique, counts)))

num_labels = len(np.unique(y_train))
y_train = to_categorical(y_train)

image_size = x_train.shape[1]
input_size = image_size * image_size

params = yaml.safe_load(open("params.yaml"))["train"]
batch_size = params["batch_size"]
hidden_units = params["hidden_units"]
dropout = params["dropout"]
num_epochs = params["num_epochs"]
lr = params["lr"]

# Model specific code
x_train = np.reshape(x_train, [-1, input_size])
x_train = x_train.astype('float32') / 255
model = Sequential()
model.add(Dense(hidden_units, activation='relu'))
model.add(Dropout(dropout))
model.add(Dense(num_labels, activation='softmax'))
# End of Model specific code

opt = tensorflow.keras.optimizers.Adam(learning_rate=lr)
model.compile(loss='categorical_crossentropy', 
              optimizer=opt,
              metrics=['accuracy'])

history = model.fit(x_train, y_train, epochs=num_epochs, batch_size=batch_size, verbose=1)

def history_to_csv(history):
    # This code is copied from https://github.com/iterative/get-started-experiments/
    keys = list(history.history.keys())
    csv_string = ",".join(["epoch"] + keys) + "\n"
    list_len = len(history.history[keys[0]])
    for i in range(list_len):
        row = (
            str(i + 1)
            + ","
            + ",".join([str(history.history[k][i]) for k in keys])
            + "\n"
        )
        csv_string += row

    return csv_string
print(history)
with open("output/train_logs.csv", "w") as f:
    f.write(history_to_csv(history))

model.summary()

model_file = os.path.join(OUTPUT_DIR, "model.h5")
model.save(model_file)
