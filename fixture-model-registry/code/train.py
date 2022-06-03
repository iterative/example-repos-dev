from mlem.api import save
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier


def main():
    data, y = load_iris(return_X_y=True, as_frame=True)
    rf = RandomForestClassifier(
        n_jobs=2,
        random_state=42,
    )
    rf.fit(data, y)

    save(
        rf,
        "rf",
        sample_data=data,
        description="Random Forest Classifier",
    )


if __name__ == "__main__":
    main()
