# release-templates

Helm chart that sets up GitOps delivery and promotion for one or more apps across environments:

| Tool | Resources |
|---|---|
| Argo CD | `AppProject` per app, `Application` per app × env, repo Secrets (git + OCI Helm) |
| Kargo | `Project` + `ProjectConfig` per app, `Warehouse`, `Stage` per env, `PromotionTask` |
| Shared | Namespace per app, Argo CD cluster Secrets for remote clusters (EKS, GKE, AKS or any Kubernetes) |

Targets **Argo CD v3.6 (argo-cd chart 10.18.x)** and **Kargo v1.12**.

## How a promotion works

1. The `Warehouse` watches the chart in the OCI registry and the release git repo, and creates Freight.
2. A `Stage` promotes Freight with the `PromotionTask`:
   clone repo → write the chart version to `<env.path>/<app>/version.yaml` → commit →
   push (or open a PR and wait for it to merge, when `kargo.openPR: true`) → `argocd-update` sets the
   Application's `targetRevision` and syncs it.
3. Values come from `<env.path>/<app>/values.yaml` in the release repo.

`env.path` defaults to `environments/<env.name>/<env.clusterName>`. Release repo layout:

```
environments/
├── local/minikube/          # environment / cluster
│   ├── qe/podinfo/          # stage / app  →  version.yaml, values.yaml
│   └── preprod/podinfo/
└── uat/                     # placeholder
```

Kargo owns `targetRevision` after the first promotion. The chart reads it back from the live
Application (`lookup`) so `helm upgrade` doesn't roll apps back to `chartVersion`.

## Test locally on minikube

Prereqs: minikube running, with Argo CD and Kargo installed from `devops/environments/local-dev`.
Argo CD needs `configs.params."application.namespaces": "*"`, which is already set there.

1. Commit and push the seed files to `main` in `calebtech/app-releases`:
   `environments/local/minikube/{qe,preprod}/podinfo/{version,values}.yaml` (already in this repo).
2. Install, using a GitHub PAT with `repo` scope (Kargo pushes version bumps):

   ```bash
   helm upgrade --install release-templates deployments/release-templates \
     -n argocd -f deployments/release-templates/values-local.yaml \
     --set secrets.gitUsername=<github-user> --set secrets.gitPassword=<github-pat>
   ```
3. Watch it:

   ```bash
   kubectl -n podinfo get warehouse,freight,stage,promotion
   kubectl -n podinfo get applications
   kubectl -n podinfo-qe get pods
   kubectl -n kargo port-forward svc/kargo-api 8443:443   # Kargo UI → https://localhost:8443
   ```

   `local-qe` auto-promotes. Promote to `local-preprod` from the Kargo UI.

## Key values

| Value | Default | Notes |
|---|---|---|
| `applications[].name` / `namespace` | — | Must be equal (the Kargo project namespace is the project name) |
| `applications[].chartVersion` | `1.9.6` | Initial `targetRevision`; Kargo changes it on promotion |
| `applications[].chartRepo`, `environments[].chartRepo` | ECR path | Override the chart registry (no `oci://`) |
| `environments[].namespaceSuffix` | `""` | Separates envs that share one cluster |
| `argocd.appsInAnyNamespace` | `true` | `false` puts Applications in `argocd.namespace` |
| `argocd.helmOciRepos` | `[]` | Registers OCI Helm registries with Argo CD |
| `kargo.openPR` | `true` | `false` pushes straight to the branch |
| `environments[].cluster.provider` | legacy aws | Argo CD cluster auth: `aws` (EKS), `gcp` (GKE), `azure` (AKS), `token`, `tls`, `exec`, `in-cluster`. See [examples/cluster-access.yaml](examples/cluster-access.yaml) |
| `secrets.create` | `true` | Git credentials for Argo CD (read) and Kargo (write). Never commit them |

## Cluster access per cloud

Argo CD needs some setup outside this chart for each cloud's identity:

| Provider | Extra Argo CD setup |
|---|---|
| `aws` | IRSA / EKS Pod Identity on `argocd-application-controller` and `argocd-server`; the role must be mapped in the target cluster (access entry or `aws-auth`) |
| `gcp` | GKE Workload Identity on the controller/server service accounts; grant `roles/container.developer` (or RBAC) on the target cluster |
| `azure` | `workloadidentity`: federated credential + `azure.workload.identity/use: "true"` label on the pods. `spn`: client secret (pass with `--set`). `msi`: managed identity on the nodes |
| `token` / `tls` | Service-account token or client cert with RBAC on the target cluster. Pass secrets with `--set` or set `cluster.create: false` and manage the Secret with External Secrets |
| `exec` | The plugin binary must exist in the Argo CD images |
