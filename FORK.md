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
| c79d10b | Optional CA injection for kubernetes, etcd, aggregation PKI (bare-metal/fedora-coreos); bootstrap pinned to `dcode/terraform-render-bootstrap@d01ebb0` (see below) |
| 78416af | Per-controller `install_disk` and `etcd_initial_cluster_state` overrides |
| ae01877 / 99f3594 | containerd `device_ownership_from_security_context` |
| b4d7018 | `etcd_extra_initial_cluster_members` |

## Fork commits in dcode/terraform-render-bootstrap

`bare-metal/fedora-coreos/kubernetes/bootstrap.tf` pins the fork's `main` by commit hash
(currently `d01ebb0`). These commits sit on top of upstream `f6d1b42` (v1.37.2):

| Commit | Change |
|---|---|
| 2be4b18 | Optional CA injection (kubernetes, etcd, aggregation PKI) |
| 8d98626 | kube-scheduler liveness `failureThreshold: 8`, matching kube-controller-manager |

Merge fork PRs with "Create a merge commit": squash or rebase changes commit hashes, and a
pinned hash that is no longer on the fork's `main` can stop resolving.

## Divergence / TODO

- [x] ~~**bare-metal/fedora-coreos is held at Kubernetes v1.36.1**~~ — resolved 2026-11-20.
      `cb695b2` (CA injection) was forward-ported onto upstream `f6d1b42` (v1.37.2) as
      `dcode/terraform-render-bootstrap@2be4b18` (branch `claude/stoic-johnson-utbjne`).
      Only conflict was `variables.tf` (kept upstream's `cloud_provider` and the six
      `*_ca_cert`/`*_ca_key` variables). `bootstrap.tf` now pins `2be4b18`; kubelet and
      README are back on v1.37.2. bare-metal/fedora-coreos is level with the rest of the repo.
- [ ] Recurring chore until CA injection is upstreamed: on every upstream Kubernetes bump,
      repeat the forward-port. Recipe:
  1. In `dcode/terraform-render-bootstrap`: `git checkout -b <branch> <new upstream sha>`,
     cherry-pick every commit in "Fork commits" above, in order
     (`git cherry-pick 2be4b18 8d98626`), resolve, then `terraform validate`. Then merge the
     old fork `main` into the branch with `git merge -s ours origin/main` so the PR merges
     cleanly, and update the table above with the new hashes.
  2. Push, and update the `ref=` in `bare-metal/fedora-coreos/kubernetes/bootstrap.tf`
     (keep the fork ref when resolving the expected merge conflict there).
  3. Keep `quay.io/poseidon/kubelet` in `butane/controller.yaml` and
     `worker/butane/worker.yaml` at the same version as the bootstrap control plane
     (kubelet must not be newer than kube-apiserver).
- [ ] Consider upstreaming CA injection to poseidon/terraform-render-bootstrap so the
      fork pin can be dropped entirely.
