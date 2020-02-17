SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
########################################
SHELL=/bin/bash
include ../../.env
T = response
$(shell mkdir -p $(T)/{routes,styles/{gzip,gunzip},icons,lualib} )
XQ := $(XQERL_CONTAINER_NAME)
OR := $(PROXY_CONTAINER_NAME)
######################################################
include setup.mk

.PHONY: test
test: styles icons routes
# styles icons routes
# routes icons icons styles.mk styles-size

.PHONY: clean-responses
clean-responses:
	@echo '## $@ ##'
	@rm -rf ./response/styles

include routes.mk icons.mk styles.mk resty.mk
