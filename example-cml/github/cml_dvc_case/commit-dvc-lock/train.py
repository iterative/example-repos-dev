from sklearn.neural_network import MLPClassifier
from sklearn.metrics import recall_score, precision_score
import json
import os
import numpy as np
import pandas as pd


# Read in data
X_train = np.genfromtxt("data/train_features.csv")
y_train = np.genfromtxt("data/train_labels.csv")
X_test = np.genfromtxt("data/test_features.csv")
y_test = np.genfromtxt("data/test_labels.csv")


# Fit a model

clf = MLPClassifier(random_state=0, max_iter=30)
clf.fit(X_train,y_train)

# Get overall accuracy
acc = clf.score(X_test, y_test)

# Get precision and recall
y_score = clf.predict(X_test)
prec = precision_score(y_test, y_score)
rec = recall_score(y_test,y_score)

# Get the loss
loss = clf.loss_curve_
pd.DataFrame(loss, columns=["loss"]).to_csv("loss.csv", index=False)

with open("metrics.json", 'w') as outfile:
        json.dump({ "accuracy": acc, "precision":prec,"recall":rec}, outfile)


