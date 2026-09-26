# sqlambda/freebsd15

A FreeBSD 15 Vagrant box for the **libvirt** provider, amd64, built with
Packer from the official release ISO. Current release: **15.1**.

The box name follows the FreeBSD **major** version. The box version follows
the **point release**: `15.1.0` is the first build of 15.1-RELEASE, and
`15.1.1` onwards are rebuilds of it (errata, security advisories, template
fixes). Pin one with `config.vm.box_version`.

## What the box provides

- `vagrant` user, password `vagrant`, the Vagrant insecure keypair (RSA and
  ed25519), passwordless `sudo`. Root password is `vagrant`.
- `sshd` at boot, DHCP on the first NIC (virtio).
- Base system updated with `freebsd-update` to the latest patch level at build
  time, and `pkg` bootstrapped against the default repository for that release.
- Python 3.12 at `/usr/local/bin/python3`, for Ansible. It is the ports'
  default version, the only one FreeBSD builds `py3*-` packages for
  (`py312-psycopg2` among them). The build fails if the default moves.
- Root filesystem UFS, grown to fill the disk on boot (`growfs`), no swap.
- No synced folder (FreeBSD base has no rsync).

## Root disk

**Root is `da0`**, on a virtio-scsi controller. The box's Vagrantfile sets
`disk_bus = "scsi"`, the same as `sqlambda/freebsd14` and `generic/freebsd14`,
so data-disk device names are identical on 14 and 15.

Any disk you attach with `:bus => 'virtio'` is virtio-blk and numbers from
**`vtbd0`**, in attach order.

If you override `disk_bus` to `virtio`, root becomes `vtbd0` and your attached
disks shift to `vtbd1` onwards. The box still boots either way, because root is
mounted by label (`/dev/gpt/rootfs`), but any path you hard-code to a data
disk moves by one.

## Build

Needs Docker and `/dev/kvm`. Packer, its qemu and vagrant plugins, and QEMU
all run in a container built from the `Dockerfile`; nothing is installed on
the host. The build runs as your user, and the ISO is cached in
`~/.cache/packer` (override with `PACKER_CACHE=`).

    make box            # ISO → build/sqlambda-freebsd15-15.1.0-libvirt-amd64.box
    make add            # vagrant box add it locally as sqlambda/freebsd15

`make add` runs on the host and needs Vagrant, as does anything that uses the
box. The container uses host networking, so while a build runs, the installer
console is on the `vnc://127.0.0.1:59xx` address packer prints.

Bumping Packer is `PACKER_VERSION` and `PACKER_SHA256` in the `Dockerfile`,
the checksum copied from HashiCorp's `packer_<version>_SHA256SUMS`.

A new point release changes `iso_url`, `iso_checksum` (copied from FreeBSD's
`CHECKSUM.SHA256-*` file, never computed locally), `box_version`, and
`BSDINSTALL_DISTSITE` in `http/installerconfig` — 15's disc1 no longer carries
the distribution sets, so the installer downloads them from that release
directory.

## License

Apache 2.0 — see [LICENSE](LICENSE).
