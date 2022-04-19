from mlem.api import load, save
from sklearn.ensemble import RandomForestClassifier


def main():
    df = load("train.csv")
    data = df.drop("target", axis=1)
    rf = RandomForestClassifier(
        n_jobs=2,
        random_state=42,
    )
    rf.fit(data, df.target)

    save(
        rf,
        "rf",
        tmp_sample_data=data,
        tags=["random-forest", "classifier"],
        description="Random Forest Classifier",
    )


if __name__ == "__main__":
    main()
