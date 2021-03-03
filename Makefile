TAG ?= latest
RUNTIME ?= sudo docker

docker:
	$(RUNTIME) build . -t slaclab/slac-ondemand:$(TAG)
	$(RUNTIME) push slaclab/slac-ondemand:$(TAG)


