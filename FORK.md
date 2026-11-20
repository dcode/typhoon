# Fork notes (dcode/typhoon)

Working notes for this fork of [poseidon/typhoon](https://github.com/poseidon/typhoon).
Read this first after time away.

## Syncing with upstream

```sh
git remote add upstream https://github.com/poseidon/typhoon.git  # once
git fetch upstream main
git merge --no-ff upstream/main   # merge, don't rebase: local commits are published
```

Expect a conflict in `bare-metal/fedora-coreos/kubernetes/bootstrap.tf` on every
upstream Kubernetes bump while the bootstrap fork pin below exists.

## Local changes carried on top of upstream

| Commit | Change |
|---|---|
| c79d10b | Optional CA injection for kubernetes, etcd, aggregation PKI (bare-metal/fedora-coreos) |
| 78416af | Per-controller `install_disk` and `etcd_initial_cluster_state` overrides |
| ae01877 / 99f3594 | containerd `device_ownership_from_security_context` |
| b4d7018 | `etcd_extra_initial_cluster_members` |

## Divergence / TODO

- [ ] **bare-metal/fedora-coreos is held at Kubernetes v1.36.1** (rest of repo: v1.37.2,
      synced 2026-11-20). Cause: `bootstrap.tf` pins
      `dcode/terraform-render-bootstrap@cb695b2` (CA injection), which is based on an
      older upstream with v1.36.1 control-plane images. The kubelet in
      `butane/controller.yaml` and `worker/butane/worker.yaml` is pinned to v1.36.1 to
      match, because a kubelet newer than kube-apiserver violates the version-skew policy.
      To unblock:
  1. In `dcode/terraform-render-bootstrap`, rebase/cherry-pick `cb695b2` onto upstream
     `f6d1b42` (v1.37.2). Only conflict: `variables.tf`, keep both upstream's
     `cloud_provider` variable and the six `*_ca_cert`/`*_ca_key` variables.
  2. Update the `ref=` in `bare-metal/fedora-coreos/kubernetes/bootstrap.tf`.
  3. Bump kubelet images back to the upstream version and restore the README version line.
- [ ] Consider upstreaming CA injection to poseidon/terraform-render-bootstrap so the
      fork pin can be dropped entirely.
