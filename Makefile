BUILD_FLAGS?=-rp

.DEFAULT_GOAL := all

all : test update build
.PHONY : all

.PHONY : test
test:

.PHONY : clean
clean:
		./bin/clean.sh

.PHONY : update
update:
		./composer_update_lockfile.sh

.PHONY : build
build:
		./build.sh $(BUILD_FLAGS)
