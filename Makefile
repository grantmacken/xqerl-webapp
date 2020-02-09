SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
###################################
include .env

.PHONY: test
test:
	@pushd tests/proxy &>/dev/null
	@make -silent
	@popd &>/dev/null

.PHONY: up
up: xqerl-up  proxy-up

.PHONY: xqerl-up
xqerl-up:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) -silent up
	@popd &>/dev/null

.PHONY: proxy-up
proxy-up: 
	@pushd proxy &>/dev/null
	@$(MAKE) -silent up
	@popd &>/dev/null

.PHONY: proxy-down
down: 
	@pushd proxy &>/dev/null
	@$(MAKE) -silent down
	@popd &>/dev/null

.PHONY: proxy-reload
proxy-reload: 
	@pushd proxy &>/dev/null
	@$(MAKE) -silent down
	@popd &>/dev/null

.PHONY: xqerl-down
xqerl-down: 
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) -silent down
	@popd &>/dev/null

.PHONY: xqerl-build
xqerl-build: 
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) -silent build
	@popd &>/dev/null

.PHONY: xqerl-clean
xqerl-clean: 
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) -silent clean
	@popd &>/dev/null

## will error if error
.PHONY: xqerl-build-watch
xqerl-build-watch:
	@pushd site/$(DOMAIN) &>/dev/null
	@while true; do $(MAKE) --silent build; \
 inotifywait -qre close_write .  &>/dev/null; done
	@popd &>/dev/null

.PHONY: assets
assets: 
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) -silent assets
	@#echo ' ---'
	@#docker exec $(PROXY_CONTAINER_NAME) kill -HUP 1
	@popd &>/dev/null




.PHONY: clean
clean: 
	@pushd proxy &>/dev/null
	@$(MAKE) -silent clean
	@popd &>/dev/null




