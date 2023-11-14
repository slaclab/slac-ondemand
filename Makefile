TAG ?= latest
RUNTIME ?= sudo podman
NOCACHE ?= 

ondemand:
	$(RUNTIME) build . $(NOCACHE) -t slaclab/slac-ondemand:$(TAG)
	$(RUNTIME) push slaclab/slac-ondemand:$(TAG)

docs:
	$(RUNTIME) build . -f Dockerfile.docs -t slaclab/sdf-docs:$(TAG)
	$(RUNTIME) push slaclab/sdf-docs:$(TAG)

gitclone:
	$(RUNTIME) build . -f Dockerfile.gitclone -t slaclab/gitclone:$(TAG)
	$(RUNTIME) push slaclab/gitclone:$(TAG)

