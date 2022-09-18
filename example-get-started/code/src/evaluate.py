import json
import math
import os
import pickle
import sys

import pandas as pd
import shap
from sklearn import metrics
from sklearn import tree
from dvclive import Live
from matplotlib import pyplot as plt


if len(sys.argv) != 3:
    sys.stderr.write("Arguments error. Usage:\n")
    sys.stderr.write("\tpython evaluate.py model features\n")
    sys.exit(1)

model_file = sys.argv[1]
train_file = os.path.join(sys.argv[2], "train.pkl")
test_file = os.path.join(sys.argv[2], "test.pkl")

def evaluate(model, matrix, dataset_name):
    """Dump all evaluation metrics and plots for given datasets."""
    eval_path = os.path.join("evaluation", dataset_name)

    labels = matrix[:, 1].toarray().astype(int)
    x = matrix[:, 2:]

    predictions_by_class = model.predict_proba(x)
    predictions = predictions_by_class[:, 1]

    # Use dvclive to log a few simple plots ...
    live = Live(eval_path)
    live.log_plot("roc", labels, predictions)
    live.log("avg_prec", metrics.average_precision_score(labels, predictions))
    live.log("roc_auc", metrics.roc_auc_score(labels, predictions))

    # ... but actually it can be done with dumping data points into a file:
    # ROC has a drop_intermediate arg that reduces the number of points.
    # https://scikit-learn.org/stable/modules/generated/sklearn.metrics.roc_curve.html#sklearn.metrics.roc_curve.
    # PRC lacks this arg, so we manually reduce to 1000 points as a rough estimate.
    precision, recall, prc_thresholds = metrics.precision_recall_curve(labels, predictions)
    nth_point = math.ceil(len(prc_thresholds) / 1000)
    prc_points = list(zip(precision, recall, prc_thresholds))[::nth_point]
    prc_file = os.path.join(eval_path, "plots", "precision_recall.json")
    with open(prc_file, "w") as fd:
        json.dump(
            {
                "prc": [
                    {"precision": p, "recall": r, "threshold": t}
                    for p, r, t in prc_points
                ]
            },
            fd,
            indent=4,
        )


    # ... confusion matrix plot
    live.log_plot("confusion_matrix", labels.squeeze(), predictions_by_class.argmax(-1))


# Load model and data.
with open(model_file, "rb") as fd:
    model = pickle.load(fd)

with open(train_file, "rb") as fd:
    train, feature_names = pickle.load(fd)

with open(test_file, "rb") as fd:
    test, _ = pickle.load(fd)

# Evaluate train and test datasets.
evaluate(model, train, "train")
evaluate(model, test, "test")

# Save feature importance and show it with your plots.
importances = model.feature_importances_
forest_importances = pd.Series(importances, index=feature_names).nlargest(n=30)
forest_importances = forest_importances.reset_index()
forest_importances.columns = ["Feature", "Mean decrease in impurity"]
forest_importances.to_csv(os.path.join("evaluation", "importance.csv"),
                          index=False)

# Save SHAP feature importance and show it with your plots.
fig, axes = plt.subplots(dpi=100)
x_arr = test[:, 2:].toarray()
explainer = shap.TreeExplainer(model, data=x_arr)
shap_values = explainer.shap_values(x_arr)[1]
shap.summary_plot(shap_values, x_arr, feature_names=feature_names, 
                  plot_size=(10,5), show=False)
plt.savefig(os.path.join("evaluation", "shap.png"))
