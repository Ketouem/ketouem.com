dev:
	hugo server --source ./site

install:
	git submodule init
	git submodule update

build:
	hugo --source ./site --baseUrl "//ketouem.com"
