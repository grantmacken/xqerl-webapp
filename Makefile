SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
###################################
include .env .version.env

.PHONY: test
test:
	@pushd tests/proxy &>/dev/null
	@make -silent
	@popd &>/dev/null

.PHONY: up
up: xqerl-up proxy-up xqerl-clean xqerl-build

.PHONY: down
down: proxy-down xqerl-down

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

.PHONY: proxy-clean
proxy-clean:
	@pushd proxy &>/dev/null
	@$(MAKE) -silent clean
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

.PHONY: proxy-info
proxy-info:
	@pushd tests/proxy &>/dev/null
	@$(MAKE) -silent info
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
	@$(MAKE) -silent
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
	@cat ../.github-access-token | docker login docker.pkg.github.com  --username $(REPO_OWNER) --password-stdin
	@docker pull docker.pkg.github.com/grantmacken/alpine-xqerl/xq:$(XQ_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-nginx/ngx:$(NGX_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-scour/scour:$(SCOUR_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:$(ZOPFLI_VER)
	@docker pull docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:$(CSSNANO_VER)




