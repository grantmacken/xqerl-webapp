SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
#####################
### SITE gmack.nz ###
#####################
include ../../.env
DOMAIN = $(notdir $(CURDIR))
T := .tmp
B := .build
D := .deploy
# shortcut aliases
XQ := $(XQERL_CONTAINER_NAME)
DEX := docker exec $(XQ)
ESCRIPT := $(DEX) xqerl escript
EVAL := $(DEX) xqerl eval

OR := $(PROXY_CONTAINER_NAME)
# DEO := docker exec $(OR)

compile =  $(ESCRIPT) bin/scripts/compile.escript ./code/src/$1
compiledLibs := 'BinList = xqerl_code_server:library_namespaces(),\
 NormalList = [binary_to_list(X) || X <- BinList],\
 io:fwrite("~1p~n",[lists:sort(NormalList)]).'

####################################################################
# targets
# make: this targets `make xqerl-compiled-code`, the first target
# xqerl-compiled-code
# the tar should be an updated when local files change
# the tar comes from the xqerl-compiled-code volume
# and not the build dir
####################################################################
# NOTE: xquery module list order is important
ModuleList := newBase60 render_feed render_note micropub routes
BuildList  := $(patsubst %,$(B)/modules/%.xqm,$(ModuleList))
DeployList := $(patsubst %,$(D)/modules/%.xqm,$(ModuleList))

VolumeList := xqerl-compiled-code xqerl-database

MountCode  := type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
MountData  := type=volume,target=$(XQERL_HOME)/data,source=xqerl-database
MountBin   := type=bind,target=$(XQERL_HOME)/bin/scripts,source=$(CURDIR)/bin

MountBuild := type=bind,target=/tmp,source=$(CURDIR)/$(B)

.PHONY: build
build: $(T)/OK

$(T)/OK: $(D)/xqerl-compiled-code.tar
	@mkdir -p $(T)
	@pushd tests &>/dev/null
	@echo 'test restXQ routes with docker IP and port'
	@$(MAKE) -silent --file restXQerl.mk clean
	@$(MAKE) -silent --file restXQerl.mk 
	@popd &>/dev/null
	@$(EVAL) $(compiledLibs) > $@
	@echo;printf %60s | tr ' ' '-' && echo

$(D)/xqerl-compiled-code.tar: $(BuildList) 
	@echo '## $(notdir $@) ##'
	@$(EVAL) $(compiledLibs)
	@echo;printf %60s | tr ' ' '-' && echo
	@mkdir -p $(dir $@)
	@docker run --rm \
 --mount $(MountCode) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) -czf - $(XQERL_HOME)/code > $@
	@echo;printf %60s | tr ' ' '-' && echo

.PHONY: clean
clean:
	@echo '##[ $@ ]##'
	@rm -f $(BuildList)
	@rm -f $(D)/xqerl-compiled-code.tar
	@rm -f $(T)/*

$(B)/modules/%.xqm: modules/%.xqm
	@echo '##[ $* ]##'
	@mkdir -p $(dir $@) && mkdir -p $(T)
	@rm -f $(T)/compile_$(*).txt
	@docker cp $(<) $(XQ):$(XQERL_HOME)/code/src
	@$(call compile,$(notdir $<)) | tee $(T)/compile_$(*).txt && echo
	@cat $(T)/compile_$(*).txt | grep -q ':I:'
	@cp $< $@

include ../.inc/*

