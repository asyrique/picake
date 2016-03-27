build:
	./build.sh

clean:
	./clean.sh

deploy:
	./deploy.sh

travis-build:
	(. ./build.sh && ./travis-clean.sh)

test+:
	(. ./test/test1.sh && ./test/test2.sh)
