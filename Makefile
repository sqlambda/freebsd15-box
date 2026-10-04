# ISO → .box in one step. `make box`, then `make add` to try it locally.
# Packer and QEMU run in a container (see Dockerfile); the host needs Docker
# and /dev/kvm. `make add` is the one host-side step, since using a box needs
# Vagrant anyway.
VERSION ?= 15.1.0
BOX     := build/sqlambda-freebsd15-$(VERSION)-libvirt-amd64.box
IMAGE   ?= sqlambda/freebsd15-build
# Shared with a host packer's default cache, so the 1.3G ISO is fetched once.
PACKER_CACHE ?= $(HOME)/.cache/packer

# Runs as the invoking user, so build/ is theirs, with the kvm group for
# /dev/kvm. Host networking keeps packer's VNC port reachable from the host,
# which is how a stuck installer gets looked at.
PACKER = docker run --rm --init --network host \
	--device /dev/kvm --group-add $$(stat -c %g /dev/kvm) \
	--user $$(id -u):$$(id -g) -e HOME=/tmp \
	-e PACKER_CACHE_DIR=/cache -v $(PACKER_CACHE):/cache \
	-v $(CURDIR):/work -w /work \
	$(IMAGE) packer

.PHONY: image validate box add clean

image:
	docker build -t $(IMAGE) .

validate: image
	mkdir -p $(PACKER_CACHE)
	$(PACKER) fmt -check freebsd15.pkr.hcl
	$(PACKER) validate -var box_version=$(VERSION) freebsd15.pkr.hcl

box: validate
	# The checksum post-processor appends, so a stale .sha256 would keep old lines.
	rm -rf build/qemu $(BOX) $(BOX).sha256
	$(PACKER) build -var box_version=$(VERSION) freebsd15.pkr.hcl

# Added through a one-box catalog rather than the bare .box file: a bare file
# always registers as version 0, so a rebuild could not be told apart from the
# build it replaced. The catalog carries VERSION, and the checksum packer wrote.
add: build/metadata.json
	vagrant box add --force build/metadata.json

build/metadata.json: $(BOX).sha256
	printf '{"name":"sqlambda/freebsd15","versions":[{"version":"%s","providers":[{"name":"libvirt","url":"file://%s","checksum_type":"sha256","checksum":"%s"}]}]}\n' \
		$(VERSION) $(abspath $(BOX)) $$(cut -f1 $(BOX).sha256) > $@

clean:
	rm -rf build
