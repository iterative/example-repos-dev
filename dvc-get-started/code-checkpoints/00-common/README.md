## DVC Get Started for Checkpoints

This project is a showcase for checkpoints features in DVC 2.0 and
[`dvclive`][dvcl]. It shows how to use checkpoints in various ways with the
provided Git tags. 

All four tags are cloned and installed similarly: 

```console
git clone https://github.com/iterative/get-started-checkpoints -b basic
cd get-started-checkpoints
python -m venv .venv
. .venv/bin/activate
python -m pip install -r requirements.txt
```

You can also clone `https://github.com/iterative/get-started-checkpoints` with
all the tags and use `git checkout` to navigate among them. 

### Tags

- `basic`: Shows how to use checkpoints by modifying `dvc.yaml`. 

In `dvc.yaml`, the following changes are done. You can also specify this by
using `--checkpoints/-c` option to `dvc stage add`.


```yaml
    outs:
      - models/fashion-mnist/model.h5:
          checkpoint: true
```

- `dvclive`: Uses [dvclive][dvcl] in a custom Tensorflow callback, in
  `train.py`. Note that `requirements.txt` for this tag contains `dvclive` as
   well. 

```python
    def on_epoch_end(self, epoch, logs=None):
        logs = logs or {}
        for metric, value in logs.items():
            dvclive.log(metric, value)
        dvclive.next_step()
```

- `python-api`: Uses [make_checkpoint()][apicp] API call in a custom Tensorflow
  callback to record a checkpoint in `train.py`.

```python
    def on_epoch_end(self, epoch, logs=None):
        if (epoch % self.frequency) == 0:
            make_checkpoint()
```

- `signal-file`: This tag shows language-independent way of
  producing checkpoints. Instead of using DVC Python API or DVClive, a signal
  file is created to set the checkpoint. 

```python
    def dvc_signal(self):
        "Generates a DVC signal file and blocks until it's deleted"
        dvc_root = os.getenv("DVC_ROOT") # Root dir of dvc project.
        if dvc_root: # Skip if not running via dvc.
            signal_file = os.path.join(dvc_root, ".dvc", "tmp",
                "DVC_CHECKPOINT")
            with open(signal_file, "w") as f: # Write empty file.
                f.write("")
            while os.path.exists(signal_file): # Wait until dvc deletes file.
                # Wait 10 milliseconds
                time.sleep(0.01)
```


