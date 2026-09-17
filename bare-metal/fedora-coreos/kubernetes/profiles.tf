locals {
  remote_kernel = "https://builds.coreos.fedoraproject.org/prod/streams/${var.os_stream}/builds/${var.os_version}/x86_64/fedora-coreos-${var.os_version}-live-kernel.x86_64"
  remote_initrd = [
    "--name main https://builds.coreos.fedoraproject.org/prod/streams/${var.os_stream}/builds/${var.os_version}/x86_64/fedora-coreos-${var.os_version}-live-initramfs.x86_64.img",
  ]

  # Split around coreos.inst.install_dev (added back per-controller below,
  # in this same position) so a controller using the module-wide default
  # renders byte-for-byte identical args to before this was made
  # per-controller - no spurious replacement of an unrelated controller's
  # already-served Matchbox profile.
  remote_args_pre = [
    "initrd=main",
    "coreos.live.rootfs_url=https://builds.coreos.fedoraproject.org/prod/streams/${var.os_stream}/builds/${var.os_version}/x86_64/fedora-coreos-${var.os_version}-live-rootfs.x86_64.img",
  ]
  remote_args_post = [
    "coreos.inst.ignition_url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
  ]

  cached_kernel = "/assets/fedora-coreos/fedora-coreos-${var.os_version}-live-kernel.x86_64"
  cached_initrd = [
    "/assets/fedora-coreos/fedora-coreos-${var.os_version}-live-initramfs.x86_64.img",
  ]

  cached_args_pre = [
    "initrd=main",
    "coreos.live.rootfs_url=${var.matchbox_http_endpoint}/assets/fedora-coreos/fedora-coreos-${var.os_version}-live-rootfs.x86_64.img",
  ]
  cached_args_post = [
    "coreos.inst.ignition_url=${var.matchbox_http_endpoint}/ignition?uuid=$${uuid}&mac=$${mac:hexhyp}",
  ]

  kernel    = var.cached_install ? local.cached_kernel : local.remote_kernel
  initrd    = var.cached_install ? local.cached_initrd : local.remote_initrd
  args_pre  = var.cached_install ? local.cached_args_pre : local.remote_args_pre
  args_post = var.cached_install ? local.cached_args_post : local.remote_args_post

  # Most controllers share var.install_disk, but heterogeneous hardware (a
  # controller whose disk layout doesn't match the others - see
  # dcode/infra#16) may need a different install target per node, so an
  # optional per-controller override takes precedence when set.
  controller_install_disks = [
    for c in var.controllers : coalesce(c.install_disk, var.install_disk)
  ]
}

# Match a controller to a profile by MAC
resource "matchbox_group" "controller" {
  count   = length(var.controllers)
  name    = format("%s-%s", var.cluster_name, var.controllers.*.name[count.index])
  profile = matchbox_profile.controllers.*.name[count.index]

  selector = {
    mac = var.controllers.*.mac[count.index]
  }
}

// Fedora CoreOS controller profile
resource "matchbox_profile" "controllers" {
  count = length(var.controllers)
  name  = format("%s-controller-%s", var.cluster_name, var.controllers.*.name[count.index])

  kernel = local.kernel
  initrd = local.initrd
  args = concat(
    local.args_pre,
    ["coreos.inst.install_dev=${local.controller_install_disks[count.index]}"],
    local.args_post,
    var.kernel_args,
  )

  raw_ignition = data.ct_config.controllers.*.rendered[count.index]
}

# Fedora CoreOS controllers
data "ct_config" "controllers" {
  count = length(var.controllers)
  content = templatefile("${path.module}/butane/controller.yaml", {
    domain_name            = var.controllers.*.domain[count.index]
    etcd_name              = var.controllers.*.name[count.index]
    etcd_initial_cluster   = join(",", formatlist("%s=https://%s:2380", var.controllers.*.name, var.controllers.*.domain))
    cluster_dns_service_ip = module.bootstrap.cluster_dns_service_ip
    ssh_authorized_key     = var.ssh_authorized_key
  })
  strict   = true
  snippets = lookup(var.snippets, var.controllers.*.name[count.index], [])
}
