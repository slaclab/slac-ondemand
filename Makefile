TAG=20200415.1

docker:
	sudo docker build . -t slaclab/slac-ondemand:${TAG}
	sudo docker push slaclab/slac-ondemand:${TAG}


