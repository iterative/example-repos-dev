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
git push --force origin tune-architecture
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

- `tune-architecture` P.R.

To create a PR from the "tune-architecture" branch:

```
gh pr create -t "Run experiments tuning architecture" \
   -B main -H tune-architecture
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
and create a P.R. using the `Experiment` button, increasing epochs from `8` to 
`12`.
