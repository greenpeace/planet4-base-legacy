SHELL := /bin/bash

BAKE_IMAGE?=p4-gpi-app-dev

BUILD_FLAGS?=-rp
BUILD_ENVIRONMENT?=develop

.DEFAULT_GOAL := all

all : clean test update build
.PHONY : all

.PHONY : test
test:

.PHONY : bake
bake:
		./bin/bake.sh -e $(BUILD_ENVIRONMENT) $(BAKE_IMAGE)

.PHONY : clean
clean:
		./bin/clean.sh

.PHONY : update
update:
		./composer_update_lockfile.sh

.PHONY : build
build:
		./bin/build.sh -e $(BUILD_ENVIRONMENT) $(BUILD_FLAGS)
