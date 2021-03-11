# dvc-checkpoints-mnist

This example DVC project uses
[checkpoints](https://dvc.org/doc/api-reference/make_checkpoint) to iteratively
train a model. The model is a simple convolutional neural network (CNN)
classifier trained on the [MNIST](http://yann.lecun.com/exdb/mnist/) data of
handwritten digits to predict the digit (0-9) in each image.

## Setup

To try it out for yourself:

1. Fork the repository and clone to your local workstation.
2. Install the prerequisites in `requirements.txt` (if you are using pip, run
   `pip install -r requirements.txt`).

## Experiment with checkpoints

Start training the model with `dvc exp run`. Run `dvc exp run` as many times as
you want to continue training.

Once the training script completes, you can view the results of each checkpoint
with:

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
* Run `dvc exp apply [checkpoint_id]` to revert to any of the prior checkpoints
  (which will update the `model.pt` output file and metrics to that point).
* Run `dvc exp run --reset` to drop all the existing checkpoints and start from
  scratch.

## How to add checkpoints to your DVC project

In `dvc.yaml`, add the `checkpoint: true` option to your model output:

```diff
     outs:
-    - model.pt
+    - model.pt:
+        checkpoint: true
```

That's it!
