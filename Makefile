TAG=20210210.0

docker:
	sudo docker build . -t slaclab/slac-ondemand:${TAG}
	sudo docker push slaclab/slac-ondemand:${TAG}


