SHELL := /bin/bash

build:
	(. ./build.sh && ./clean.sh)

clean:
	./clean.sh

deploy:
	./deploy.sh

travis-build:
	(. ./build.sh && ./clean.sh)

test+:
	(. ./test/test1.sh && ./test/test2.sh)
