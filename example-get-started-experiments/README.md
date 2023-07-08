Generate the actual repo by running: 

```shell
bash generate.sh
```

The repo generated in `build/example-get-started-experiments` is intended to be 
published on https://github.com/iterative/example-get-started-experiments. 
Make sure the Github repo exists first and that you have appropriate write 
permissions.

Run these commands to force push it:

```shell
cd build/example-get-started-experiments
git remote add origin git remote add origin git@github.com:<slug>/example-get-started-experiments.git
git push --force origin main
# we push git tags one by one for Studio to receive webhooks:
git tag --sort=creatordate | xargs -n 1 git push --force origin
```

Run these to drop and then rewrite the experiment references on the repo:

```shell
source .venv/bin/activate
dvc exp remove -A -g origin
dvc exp push origin -A
```

To push a copy to GitLab:

```shell
git remote add gitlab git@gitlab.com:iterative.ai/example-get-started-experiments.git
git push --force gitlab main
# we push git tags one by one for Studio to receive webhooks:
git tag --sort=creatordate | xargs -n 1 git push --force gitlab
# push experiments
dvc exp remove -A -g gitlab
dvc exp push gitlab -A
```

Finally, return to the directory where you started:

```shell
cd ../..
```

You may remove the generated repo with:

```shell
rm -fR build
```

To update the project in Studio, follow the instructions at:

https://github.com/iterative/studio/wiki/Updating-and-synchronizing-demo-project


Pay attention to whether experiments shown in experiments table are "detached"
or if the experiments you just pushed doesn't show up in the Project table.

Manual Studio PR:

Once the repo has been generated and pushed, go to the 
[corresponding Studio project](https://studio.iterative.ai/team/Iterative/projects/example-get-started-experiments-y8toqd433r) 
and create a PR from the best of the 3 experiments that are found in the latest
commit of the `main` branch.
