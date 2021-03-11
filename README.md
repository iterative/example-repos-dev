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
┏━━━━━━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━┓
┃ Experiment      ┃ Created  ┃    acc ┃
┡━━━━━━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━┩
│ workspace       │ -        │ 0.4115 │
│ python_agnostic │ 02:59 PM │      - │
│ │ ╓ exp-c61e2   │ 03:01 PM │ 0.4115 │
│ │ ╟ 1d97417     │ 03:01 PM │ 0.2973 │
│ │ ╟ e8dc64d     │ 03:00 PM │ 0.1282 │
│ ├─╨ d28a6fd     │ 02:59 PM │  0.101 │
└─────────────────┴──────────┴────────┘
```

You can also:
* Run `dvc exp apply [checkpoint_id]` to revert to any of the prior checkpoints
  (which will update the `model.pt` output file and metrics to that point).
* Run `dvc exp run --reset` to drop all the existing checkpoints and start from
  scratch.

## How to add checkpoints to your DVC project

By default, DVC will delete the outputs before running a stage. To read in the
weights from the previously trained model output, this behavior must be
disabled.

To do so, in `dvc.yaml`, add the `checkpoint: true` option to your model output:

```diff
     outs:
-    - model.pt
+    - model.pt:
+        checkpoint: true
```

That's it!
