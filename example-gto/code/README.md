# Example GTO Model Registry

This repo is an example of [Model Registry] built with [GTO]. The model dashboard:

<big><pre>
$ gto show
╒══════════╤══════════╤═════════╤═════════╤════════════╕
│ name     │ latest   │ #dev    │ #prod   │ #staging   │
╞══════════╪══════════╪═════════╪═════════╪════════════╡
│ churn    │ [v3.1.1](https://github.com/iterative/example-gto/releases/tag/churn@v3.1.1)   │ [v3.1.1](https://github.com/iterative/example-gto/releases/tag/churn%23dev%235)  │ [v3.0.0](https://github.com/iterative/example-gto/releases/tag/churn%23prod%233)  │ [v3.1.0](https://github.com/iterative/example-gto/releases/tag/churn%23staging%232)     │
│ segment  │ [v0.4.1](https://github.com/iterative/example-gto/releases/tag/segment@v0.4.1)   │ [v0.4.1](https://github.com/iterative/example-gto/releases/tag/segment%23dev%231)  │ -       │ -          │
│ cv-class │ [v0.1.13](https://github.com/iterative/example-gto/releases/tag/cv-class@v0.1.13)  │ -       │ -       │ -          │
╘══════════╧══════════╧═════════╧═════════╧════════════╛
</pre></big>

- The `latest` column shows the latest model versions,
- The `#dev` column represent model versions promoted to a Stage `dev` (same for
  other columns starting with `#`),
- Versions are registered and promoted to Stages by [Git tags] - you can click the
  links to see the which specific Git tag did it,
- Artifact metadata like `path` and `description` is stored in
  [`artifacts.yaml`],
- [Github Actions page] of this repo have examples of workflows where we act
  upon these Git tags.

Branch [`mlem`] contains a version that also uses [MLEM] to deploy a model in CI/CD
upon deployment stage assignment. Check out the deployed service at
http://mlem-dev.herokuapp.com/docs.

🧑‍💻 To continue learning, head to [Get Started with GTO].

[github actions page]: https://github.com/iterative/example-gto/actions
[get started with gto]: https://mlem.ai/doc/gto/get-started
[model registry]: https://mlem.ai/doc/use-cases/model-registry
[`mlem`]: https://github.com/iterative/example-gto/tree/mlem
[mlem]: https://mlem.ai/
[gto]: https://github.com/iterative/gto
[git tags]: https://github.com/iterative/example-gto/tags
[`artifacts.yaml`]:
  https://github.com/iterative/example-gto/blob/main/artifacts.yaml
