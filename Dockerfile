# The build toolchain — packer, its qemu and vagrant plugins, and QEMU — so the
# host needs only Docker and /dev/kvm. The Makefile runs every packer step in
# this image; nothing here is part of the box itself.
FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip qemu-system-x86 qemu-utils \
 && rm -rf /var/lib/apt/lists/*

# From packer_<version>_SHA256SUMS on releases.hashicorp.com, never computed
# locally — the same rule as the ISO checksum.
ARG PACKER_VERSION=1.16.1
ARG PACKER_SHA256=af38a9e93e4ed1b9ca68206ae969c64c300c82a3dde46a780dfa629f0867f651
RUN curl -fsSLo /tmp/packer.zip \
      "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" \
 && echo "${PACKER_SHA256}  /tmp/packer.zip" | sha256sum -c - \
 && unzip -q -d /usr/local/bin /tmp/packer.zip \
 && rm /tmp/packer.zip

# Plugins are baked in, so a build never writes to the host's ~/.config/packer.
# The build runs as the invoking user, hence world-readable.
ENV PACKER_PLUGIN_PATH=/opt/packer/plugins \
    CHECKPOINT_DISABLE=1
COPY freebsd15.pkr.hcl /tmp/
RUN packer init /tmp/freebsd15.pkr.hcl \
 && chmod -R a+rX /opt/packer \
 && rm /tmp/freebsd15.pkr.hcl
