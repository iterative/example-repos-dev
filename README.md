# dvc-checkpoints-mnist

This example DVC project demonstrates the different ways to employ
[Checkpoint Experiments](https://dvc.org/doc/user-guide/experiment-management#checkpoints-in-source-code)
with DVC.

This scenario uses [DVCLive](https://dvc.org/doc/dvclive) to generate
[checkpoints](https://dvc.org/doc/api-reference/make_checkpoint) for iterative
model training. The model is a simple convolutional neural network (CNN)
classifier trained on the [MNIST](http://yann.lecun.com/exdb/mnist/) data of
handwritten digits to predict the digit (0-9) in each image.

<details>

<summary>🔄 Switch between scenarios</summary>
<br/>

This repo has several
[branches](https://github.com/iterative/dvc-checkpoints-mnist/branches) to this
that show different methods for using checkpoints on a similar pipeline:

- The [live](https://github.com/iterative/dvc-checkpoints-mnist/edit/live)
  scenario introduces full-featured checkpoint usage — integrating with
  [DVCLive](https://github.com/iterative/dvclive).
- The [basic](https://github.com/iterative/dvc-checkpoints-mnist/tree/basic)
  scenario uses single-checkpoint experiments to illustrate how checkpoints work
  in a simple way.
- The
  [Python-only](https://github.com/iterative/dvc-checkpoints-mnist/tree/make_checkpoint)
  variation features the
  [make_checkpoint](https://dvc.org/doc/api-reference/make_checkpoint) function
  from DVC's Python API.
- Contrastingly, the
  [signal file](https://github.com/iterative/dvc-checkpoints-mnist/tree/signal_file)
  scenario shows how to make your own signal files (applicable to any
  programming language).
- Finally, our
  [full pipeline](https://github.com/iterative/dvc-checkpoints-mnist/tree/full_pipeline)
  scenario elaborates on the full-featured usage with a more advanced process.

</details>

## Setup

To try it out for yourself:

1. Fork the repository and clone to your local workstation.
2. Install the prerequisites in `requirements.txt` (if you are using pip, run
   `pip install -r requirements.txt`).

## Experimenting

Start training the model with `dvc exp run`. It will train for 10 epochs (you
can use `Ctrl-C` to cancel at any time and still recover the results of the
completed epochs), each of which will generate a checkpoint.

Dvclive will track performance at each checkpoint. Open `logs.html` in your web
browser during training to track performance over time (you will need to refresh
after each epoch completes to see updates). Metrics will also be logged to
`.tsv` files in the `logs` directory.

Once the training script completes, you can view the results of the experiment
with:

```bash
$ dvc exp show
┏━━━━━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━┳━━━━━━━━┓
┃ Experiment    ┃ Created  ┃ step ┃    acc ┃
┡━━━━━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━╇━━━━━━━━┩
│ workspace     │ -        │    9 │ 0.4997 │
│ live          │ 03:43 PM │    - │        │
│ │ ╓ exp-34e55 │ 03:45 PM │    9 │ 0.4997 │
│ │ ╟ 2fe819e   │ 03:45 PM │    8 │ 0.4394 │
│ │ ╟ 3da85f8   │ 03:45 PM │    7 │ 0.4329 │
│ │ ╟ 4f64a8e   │ 03:44 PM │    6 │ 0.4686 │
│ │ ╟ b9bee58   │ 03:44 PM │    5 │ 0.2973 │
│ │ ╟ e2c5e8f   │ 03:44 PM │    4 │ 0.4004 │
│ │ ╟ c202f62   │ 03:44 PM │    3 │ 0.1468 │
│ │ ╟ eb0ecc4   │ 03:43 PM │    2 │  0.188 │
│ │ ╟ 28b170f   │ 03:43 PM │    1 │ 0.0904 │
│ ├─╨ 9c705fc   │ 03:43 PM │    0 │ 0.0894 │
└───────────────┴──────────┴──────┴────────┘
```

You can manage it like any other DVC
[experiments](https://dvc.org/doc/start/experiments), including:
* Run `dvc exp run` again to continue training from the last checkpoint.
* Run `dvc exp apply [checkpoint_id]` to revert to any of the prior checkpoints
  (which will update the `model.pt` output file and metrics to that point).
* Run `dvc exp run --reset` to drop all the existing checkpoints and start from
  scratch.

## Adding dvclive checkpoints to a DVC project

Using dvclive to add checkpoints to a DVC project requires a few additional
lines of code.

In your training script, use `dvclive.log()` to log metrics and
`dvclive.next_step()` to make a checkpoint with those metrics. See the
[train.py](train.py) script for an example:

```python
    # Iterate over training epochs.
    for i in range(1, EPOCHS+1):
        train(model, x_train, y_train)
        torch.save(model.state_dict(), "model.pt")
        # Evaluate and checkpoint.
        metrics = evaluate(model, x_test, y_test)
        for metric, value in metrics.items():
            dvclive.log(metric, value)
        dvclive.next_step()
```

Then, in `dvc.yaml`, add the `checkpoint: true` option to your model output and
a `live` section to your stage output. See [dvc.yaml](dvc.yaml) for an example:

```yaml
stages:
  train:
    cmd: python train.py
    deps:
    - train.py
    outs:
    - model.pt:
        checkpoint: true
    live:
      logs:
        summary: true
        html: true
```

If you do not already have a `dvc.yaml` stage, you can use [dvc stage
add](https://dvc.org/doc/command-reference/stage/add) to create it:

```bash
$ dvc stage add -n train -d train.py -c model.pt --live logs python train.py
```

That's it! For users already familiar with logging metrics in DVC, note that you
no longer need a `metrics` section in `dvc.yaml` since dvclive is already
logging metrics.
