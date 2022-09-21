HUGO_GOOGLEANALYTICS ?=

dev:
	hugo server --source ./site

install:
	git submodule init
	git submodule update

build:
	HUGO_GOOGLEANALYTICS=$(HUGO_GOOGLEANALYTICS) hugo --source ./site  --destination ../build --baseUrl "//ketouem.com/"
