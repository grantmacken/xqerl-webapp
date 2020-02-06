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
up: proxy-up

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

.PHONY: down
down: 
	@pushd proxy &>/dev/null
	@$(MAKE) -silent down
	@popd &>/dev/null

.PHONY: clean
clean: 
	@pushd proxy &>/dev/null
	@$(MAKE) -silent clean
	@popd &>/dev/null




