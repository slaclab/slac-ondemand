TAG ?= dev_ood3
RUNTIME ?= sudo podman
NOCACHE ?= 

build:
	$(RUNTIME) build . $(NOCACHE) -t slaclab/slac-ondemand:$(TAG)

push:
	$(RUNTIME) push slaclab/slac-ondemand:$(TAG)

ondemand: build push

docs:
	$(RUNTIME) build . -f Dockerfile.docs -t slaclab/sdf-docs:$(TAG)
	$(RUNTIME) push slaclab/sdf-docs:$(TAG)

gitclone:
	$(RUNTIME) build . -f Dockerfile.gitclone -t slaclab/gitclone:$(TAG)
	$(RUNTIME) push slaclab/gitclone:$(TAG)

