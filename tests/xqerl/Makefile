SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
########################################
include ../../.env
XQ := $(XQERL_CONTAINER_NAME)
DOMAIN = gmack.nz
$(shell mkdir -p res/routes )
XQ := $(XQERL_CONTAINER_NAME)
xqAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
URL := http://$(xqAddress):$(XQERL_PORT)/$(DOMAIN)

##############################################

GET = curl --silent --show-error \
 --write-out $(WriteOut) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)$1 > $2

##############################################

include ../call.mk ../writeout.mk

.PHONY: test
test: routes
# styles icons routes
# routes icons icons styles.mk styles-size

.PHONY: clean
clean: clean-routes
	@echo ' - start afresh by removing previous responses'


include routes.mk
