Generate the actual repo by running: 

```
bash generate.sh
```

The repo generated in `build/example-get-started-experiments` is intended to be 
published on https://github.com/iterative/example-get-started-experiments. 
Make sure the Github repo exists first and that you have appropriate write 
permissions.

Run these commands to force push it:

```
cd build/example-get-started-experiments
git remote add origin https://github.com/iterative/example-get-started-experiments.git
git push --force origin main
git push --force origin --tags
```

Run these to drop and then rewrite the experiment references on the repo:

```
source .venv/bin/activate
dvc exp remove -A -g origin
dvc exp push origin -A
```

And this to clean the remote cache to only contain the last iteration:

```
dvc gc -c --all-commits --all-experiments
```

Finally, return to the directory where you started:

```
cd ../..
```

You may remove the generated repo with:

```
rm -fR build
```

- Manual Studio P.R.

Once the repo has been generated and pushed, go to the 
[corresponding Studio project](https://studio.iterative.ai/team/Iterative/projects/example-get-started-experiments-y8toqd433r) 
and create a P.R. from the best of the 3 experiments that are found in the latest commit of `main` branch.

- Add a model to Studio Model Registry

Go to Studio MR and click "Add a model". Details:
```
name: pool-segmentation
path: models/model.pkl
description: "This is a Computer Vision (CV) model that solves the problem of segmenting out swimming pools from satellite images"
labels: cv, satellite-images, segmentation
```
Fill the `path=models/model.pkl` and add a model to a separate branch. 
Copy other details from the existing repo or fill them from scratch. 
Register new version and assign `dev` stage to it.
Open the public MR from studio.iterative.ai, find the model, copy URL to model details page.
Post that url in the PR created by Studio.
