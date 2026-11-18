# app-releases

GitOps release repo: **what runs where is defined here**. Argo CD deploys from this repo and
Kargo promotes by committing to it.

```
app-releases/
├── deployments/release-templates/   # Helm chart: Argo CD Applications + Kargo pipeline per app/env
└── environments/                    # desired state per environment
    ├── local/minikube/<stage>/<app>/  # Chart.yaml (pinned app version) + values.yaml
    └── uat/                           # placeholder
```

- **Deploy or change config:** open a PR that edits `environments/`. Once it merges, Argo CD syncs it.
- **Release a new app version:** publish the app's chart; Kargo picks it up and promotes it stage by stage.
- **Set up or change the pipeline:** see [deployments/release-templates/README.md](deployments/release-templates/README.md).

The `release-templates` chart is published to `oci://ghcr.io/calebtech/charts` by
[.github/workflows/helm-charts.yaml](.github/workflows/helm-charts.yaml). Bump `version` in its
`Chart.yaml` to release a new chart version.
