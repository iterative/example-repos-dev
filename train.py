"""Model training and evaluation."""
import json
import yaml
import os
import torch
import torch.nn.functional as F
import torchvision
import dvclive


EPOCHS = 10


# See https://github.com/pytorch/vision/issues/3549.
torchvision.datasets.MNIST.resources = [
            ('https://ossci-datasets.s3.amazonaws.com/mnist/train-images-idx3-ubyte.gz', 'f68b3c2dcbeaaa9fbdd348bbdeb94873'),
            ('https://ossci-datasets.s3.amazonaws.com/mnist/train-labels-idx1-ubyte.gz', 'd53e105ee54ea40749a09fcbcd1e9432'),
            ('https://ossci-datasets.s3.amazonaws.com/mnist/t10k-images-idx3-ubyte.gz', '9fb629c4189551a2d022fa330f9573f3'),
            ('https://ossci-datasets.s3.amazonaws.com/mnist/t10k-labels-idx1-ubyte.gz', 'ec29112dd5afa0611ce80d1b7f02629c')
        ]


class ConvNet(torch.nn.Module):
    """Toy convolutional neural net."""
    def __init__(self):
        super().__init__()
        self.conv1 = torch.nn.Conv2d(1, 8, 3, padding=1)
        self.maxpool1 = torch.nn.MaxPool2d(2)
        self.conv2 = torch.nn.Conv2d(8, 16, 3, padding=1)
        self.dense1 = torch.nn.Linear(16*14*14, 32)
        self.dense2 = torch.nn.Linear(32, 10)

    def forward(self, x):
        x = F.relu(self.conv1(x))
        x = self.maxpool1(x)
        x = F.relu(self.conv2(x))
        x = x.view(-1, 16*14*14)
        x = F.relu(self.dense1(x))
        x = self.dense2(x)
        return x


def transform(dataset):
    """Get inputs and targets from dataset."""
    x = dataset.data.reshape(len(dataset.data), 1, 28, 28)/255
    y = dataset.targets
    return x, y


def train(model, x, y, lr, weight_decay):
    """Train a single epoch."""
    model.train()
    criterion = torch.nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(model.parameters(), lr=lr,
                                 weight_decay=weight_decay)
    y_pred = model(x)
    loss = criterion(y_pred, y)
    optimizer.zero_grad()
    loss.backward()
    optimizer.step()


def predict(model, x):
    """Get model prediction scores."""
    model.eval()
    with torch.no_grad():
        y_pred = model(x)
    return y_pred


def get_metrics(y, y_pred, y_pred_label):
    """Get loss and accuracy metrics."""
    metrics = {}
    criterion = torch.nn.CrossEntropyLoss()
    metrics["loss"] = criterion(y_pred, y).item()
    metrics["acc"] = (y_pred_label == y).sum().item()/len(y)
    return metrics


def evaluate(model, x, y):
    """Evaluate model and save metrics."""
    scores = predict(model, x)
    _, labels = torch.max(scores, 1)
    predictions = [{
                    "actual": int(actual),
                    "predicted": int(predicted)
                   } for actual, predicted in zip(y, labels)]
    with open("predictions.json", "w") as f:
        json.dump(predictions, f)
    metrics = get_metrics(y, scores, labels)
    return metrics


def main():
    """Train model and evaluate on test data."""
    torch.manual_seed(0)
    model = ConvNet()
    # Load model.
    if os.path.exists("model.pt"):
        model.load_state_dict(torch.load("model.pt"))
    # Load params.
    with open("params.yaml") as f:
        params = yaml.safe_load(f)
    torch.manual_seed(params["seed"])
    # Load train and test data.
    mnist_train = torchvision.datasets.MNIST("data")
    x_train, y_train = transform(mnist_train)
    mnist_test = torchvision.datasets.MNIST("data", train=False)
    x_test, y_test = transform(mnist_test)
    # Iterate over training epochs.
    for i in range(1, EPOCHS+1):
        # Train in batches.
        train_loader = torch.utils.data.DataLoader(
                dataset=list(zip(x_train, y_train)),
                batch_size=512,
                shuffle=True)
        for x_batch, y_batch in train_loader:
            train(model, x_batch, y_batch, params["lr"], params["weight_decay"])
        torch.save(model.state_dict(), "model.pt")
        # Evaluate and checkpoint.
        metrics = evaluate(model, x_test, y_test)
        for k, v in metrics.items():
            dvclive.log(k, v)
        dvclive.next_step()


if __name__ == "__main__":
    main()
