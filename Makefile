COMPOSER?=composer-dev.json
FROM_TAG?=develop
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
		COMPOSER=$(COMPOSER) FROM_TAG=$(FROM_TAG) ./build.sh $(BUILD_FLAGS)
