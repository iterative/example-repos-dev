import json

from mlem.api import apply
from mlem.core.metadata import load
from sklearn import metrics


def main():
    y_pred = apply("rf", "test_x.csv", method="predict_proba")
    y_true = load("test_y.csv")
    roc_auc = metrics.roc_auc_score(y_true, y_pred, multi_class="ovr")

    with open("metrics.json", "w") as fd:
        json.dump({"roc_auc": roc_auc}, fd, indent=4)


if __name__ == "__main__":
    main()
