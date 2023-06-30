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
git remote add private https://github.com/iterative/example-get-started-experiments-private.git
git push --force origin main
git push --force private main
# we push git tags one by one for Studio to receive webhooks:
git tag --sort=creatordate | xargs -n 1 git push --force origin
git tag --sort=creatordate | xargs -n 1 git push --force private
```

Run these to drop and then rewrite the experiment references on the repo:

```
source .venv/bin/activate
dvc exp remove -A -g origin
dvc exp remove -A -g private
dvc exp push origin -A
dvc exp push private -A
```

And this to clean the remote cache to only contain the last iteration:

```
dvc gc -c --all-commits --all-experiments
```

To push a copy to GitLab:

```
git remote add gitlab git@gitlab.com:iterative.ai/example-get-started-experiments.git
git push --force gitlab main
# we push git tags one by one for Studio to receive webhooks:
git tag --sort=creatordate | xargs -n 1 git push --force gitlab
# push experiments
dvc exp remove -A -g gitlab
dvc exp push gitlab -A
```
Finally, return to the directory where you started:

```
cd ../..
```

You may remove the generated repo with:

```
rm -fR build
```

Note that you may need to reparse the repo. Pay attention to whether experiments shown
in experiments table are "detached" or if the experiments you just pushed doesn't
show up in the Project table.

- Manual Studio P.R.

Once the repo has been generated and pushed, go to the 
[corresponding Studio project](https://studio.iterative.ai/team/Iterative/projects/example-get-started-experiments-y8toqd433r) 
and create a P.R. from the best of the 3 experiments that are found in the latest commit of `main` branch.
