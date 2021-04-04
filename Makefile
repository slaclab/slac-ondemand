TAG ?= latest
RUNTIME ?= sudo docker
NOCACHE ?= 

docker:
	$(RUNTIME) build . $(NOCACHE) -t slaclab/slac-ondemand:$(TAG)
	$(RUNTIME) push slaclab/slac-ondemand:$(TAG)


