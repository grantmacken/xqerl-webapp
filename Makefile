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
up: xqerl-up proxy-up xqerl-clean xqerl-build

.PHONY: proxy-up
proxy-up:
	@pushd proxy &>/dev/null
	@$(MAKE) -silent up
	@popd &>/dev/null

.PHONY: proxy-down
proxy-down:
	@pushd proxy &>/dev/null
	@$(MAKE) -silent down
	@popd &>/dev/null

.PHONY: certs-into-vol
certs-into-vol:
	@pushd proxy &>/dev/null
	@$(MAKE) -silent $@
	@popd &>/dev/null

.PHONY: proxy-build
proxy-build:
	@pushd proxy &>/dev/null
	@$(MAKE) -silent build
	@popd &>/dev/null

.PHONY: proxy-reload
proxy-reload:
	@pushd proxy &>/dev/null
	@$(MAKE) -silent reload
	@popd &>/dev/null

.PHONY: proxy-tests
proxy-tests:
	@pushd tests/proxy &>/dev/null
	@$(MAKE) -silent
	@popd &>/dev/null

.PHONY: xqerl-up
xqerl-up:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) -silent up
	@popd &>/dev/null

.PHONY: xqerl-info
xqerl-info:
	@pushd site/$(DOMAIN) &>/dev/null
	@$(MAKE) -silent info
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

.PHONY: xqerl-tests
xqerl-tests:
	@pushd tests/xqerl &>/dev/null
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

.PHONY: pull-pkgs
pull-pkgs:
	@#docker login docker.pkg.github.com --username $(REPO_NAME)
	@cat ../.github-access-token | \
 docker login docker.pkg.github.com  --username $(REPO_OWNER) --password-stdin
	@# docker pull $(PROXY_DOCKER_IMAGE) have to use local image due to mse2a SSE instruction set
	@docker pull docker.pkg.github.com/grantmacken/alpine-scour/scour:0.0.2
	@docker pull docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1
	@docker pull docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3

.PHONY: clean
clean:
	@pushd proxy &>/dev/null
	@$(MAKE) -silent clean
	@popd &>/dev/null
