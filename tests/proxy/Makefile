SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
########################################
include ../../.env
T = res
$(shell mkdir -p res/{routes,styles,icons} )
XQ  := $(XQERL_CONTAINER_NAME)
NGX := $(PROXY_CONTAINER_NAME)

proxyAddress := $(shell docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(NGX))
proxyResolve :=  --resolve $(DOMAIN):443:$(proxyAddress) --resolve $(DOMAIN):80:$(proxyAddress)
URL := https://$(DOMAIN)

######################################################

GET = curl --silent --show-error \
 $(proxyResolve) \
 -H 'Host: $(DOMAIN)' \
 --write-out $(WriteOut) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)$1 > $2

binGET = curl --silent --show-error \
 $(proxyResolve) \
 -H 'Host: $(DOMAIN)' \
 --write-out $(WriteOut) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)$1 > $2

include ../call.mk ../writeout.mk

######################################################

.PHONY: test
test: styles icons routes
# styles icons routes
# routes icons icons styles.mk styles-size

.PHONY: clean
clean:  clean-routes clean-icons clean-styles

include routes.mk icons.mk styles.mk
# resty.mk
