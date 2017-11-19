COMPOSER?=composer-dev.json
FROM_TAG?=latest
BUILD_FLAGS?=-rp

.DEFAULT_GOAL := all

all : test update build
.PHONY : all

.PHONY : test
test:

.PHONY : update
update:
		./composer_update_lockfile.sh COMPOSER=$(COMPOSER)

.PHONY : build
build:
		./build.sh $(BUILD_FLAGS) COMPOSER=$(COMPOSER) FROM_TAG=$(FROM_TAG)
