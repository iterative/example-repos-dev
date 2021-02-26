# dvc-checkpoints-mnist

This example DVC project uses [checkpoints](https://dvc.org/doc/api-reference/make_checkpoint) to iteratively train a model. The model is a simple convolutional neural network (CNN) classifier trained on the [MNIST](http://yann.lecun.com/exdb/mnist/) data of handwritten digits to predict the digit (0-9) in each image.

## Setup

To try it out for yourself:

1. Fork the repository and clone to your local workstation.
2. Install the prerequisites in `requirements.txt` (if you are using pip, run `pip install -r requirements.txt`).

## Experiment with checkpoints

Start training the model with `dvc exp run`. It will train for 10 epochs (you can also use `Ctrl-C` to cancel at any time and still recover the results of the completed epochs).

Once the training script completes, you can view the results of each checkpoint with:

```bash
$ dvc exp show
┏━━━━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━┓
┃ Experiment    ┃ Created  ┃    acc ┃
┡━━━━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━┩
│ workspace     │ -        │ 0.5633 │
│ minimal       │ 04:37 PM │      - │
│ │ ╓ exp-ef310 │ 04:40 PM │ 0.5633 │
│ │ ╟ ba076b6   │ 04:40 PM │ 0.5315 │
│ │ ╟ 9cf2f6e   │ 04:40 PM │  0.535 │
│ │ ╟ 354d175   │ 04:40 PM │ 0.5652 │
│ │ ╟ d3b5f6b   │ 04:40 PM │ 0.5418 │
│ │ ╟ 0b83b74   │ 04:39 PM │ 0.6222 │
│ │ ╟ 9ef0fa3   │ 04:39 PM │ 0.5687 │
│ │ ╟ ab414d0   │ 04:39 PM │ 0.5839 │
│ │ ╟ 1a0780d   │ 04:39 PM │ 0.3916 │
│ ├─╨ 6e313d1   │ 04:38 PM │ 0.1894 │
└───────────────┴──────────┴────────┘
```

You can also:
* Run `dvc exp run` again to continue training from the last checkpoint.
* Run `dvc exp apply [checkpoint_id]` to revert to any of the prior checkpoints (which will update the `model.pt` output file and metrics to that point).
* Run `dvc exp run --reset` to drop all the existing checkpoints and start from scratch.

## How to add checkpoints to your DVC project

Adding checkpoints to a DVC project requires a few additional lines of code.

In your script that reports metrics, add the `make_checkpoint()` function to be called whenever you want to record a checkpoint (every model epoch in this case, but it can be less frequently if you want less noise):

```diff
--- a/train.py
+++ b/train.py
@@ -5,6 +5,7 @@ import os
 import torch
 import torch.nn.functional as F
 import torchvision
+from dvc.api import make_checkpoint


 EPOCHS = 10
@@ -102,6 +103,7 @@ def main():
         torch.save(model.state_dict(), "model.pt")
         # Evaluate and checkpoint.
         evaluate(model, x_test, y_test)
+        make_checkpoint()


 if __name__ == "__main__":
```

Then, in `dvc.yaml`, add the `checkpoint: true` option to your model output:

```diff
     outs:
-    - model.pt
+    - model.pt:
+        checkpoint: true
```

That's it!
