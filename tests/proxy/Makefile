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
$(shell mkdir -p $(T)/{routes,styles,icons,lualib} )
XQ := $(XQERL_CONTAINER_NAME)
OR := $(PROXY_CONTAINER_NAME)
######################################################

.PHONY: test
test: styles icons routes
# styles icons routes
# routes icons icons styles.mk styles-size

.PHONY: clean
clean:  clean-routes clean-icons clean-styles

include setup.mk routes.mk icons.mk styles.mk
# resty.mk
