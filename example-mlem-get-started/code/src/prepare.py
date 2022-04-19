from mlem.api import save
from sklearn.datasets import load_iris
from sklearn.model_selection import train_test_split


def main():
    data, y = load_iris(return_X_y=True, as_frame=True)
    data["target"] = y
    train_data, test_data = train_test_split(data, random_state=42)
    save(train_data, "train.csv")
    save(test_data.drop("target", axis=1), "test_x.csv")
    save(test_data[["target"]], "test_y.csv")


if __name__ == "__main__":
    main()
