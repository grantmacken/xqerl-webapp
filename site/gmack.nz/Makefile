SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
#####################
### SITE gmack.nz ###
#####################
include $(abspath ../../.env)
T := .tmp
B := .build
D := ../../deploy
$(shell mkdir -p ./{$(D),$(T)/$(DOMAIN)/resources/{icons,styles,images,scripts},$(B)/{modules,$(DOMAIN)/resources/{icons,styles,images,scripts}}})


# shortcut aliases
XQ := $(XQERL_CONTAINER_NAME)
OR := $(PROXY_CONTAINER_NAME)
DEX := docker exec $(XQ)
ESCRIPT := $(DEX) xqerl escript
EVAL := $(DEX) xqerl eval

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
ModuleList := newBase60 render_feed render_feed render_note routes
# render_feed render_note micropub routes
BuildList  := $(patsubst %,$(B)/modules/%.xqm,$(ModuleList))
VolumeList := xqerl-compiled-code xqerl-database

MountCode  := type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
MountData  := type=volume,target=$(XQERL_HOME)/data,source=xqerl-database
MountBin   := type=bind,target=$(XQERL_HOME)/bin/scripts,source=$(CURDIR)/bin
MountAssets  := type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets
MountBuild := type=bind,target=/tmp,source=$(CURDIR)/$(B)

.PHONY: build
build: $(D)/xqerl-compiled-code.tar

.PHONY: clean
clean: clean-tmp
	@echo '##[ $@ ]##'
	@rm -f $(BuildList)
	@rm -f $(D)/xqerl-compiled-code.tar

.PHONY: clean-tmp
clean-tmp:
	@rm -fr $(T)/*

$(D)/xqerl-compiled-code.tar: $(BuildList) 
	@# echo '## $(notdir $@) ##'
	@# $(EVAL) $(compiledLibs)
	@docker run --rm \
 --mount $(MountCode) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) -czf - $(XQERL_HOME)/code &>/dev/null > $@
	@#echo;printf %60s | tr ' ' '-' && echo

$(B)/modules/%.xqm: modules/%.xqm
	@#echo '##[ $* ]##'
	@rm -f $(T)/compile_$(*).txt
	@docker cp $(<) $(XQ):$(XQERL_HOME)/code/src
	@$(call compile,$(notdir $<)) | tee $(T)/compile_$(*).txt && echo
	@grep -q ':I:' $(T)/compile_$(*).txt
	@cp $< $@

####################
### XQERL UP DOWN ##
####################

xqRunning != docker ps --all --filter name=$(XQ) --format '{{.Status}}' | grep -oP '^Up' || true

define xqRun
 docker run --rm  \
 --mount $(MountCode) \
 --mount $(MountData) \
 --mount $(MountBin) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_DOCKER_IMAGE)
endef

.PHONY: up
up: clean-tmp $(T)/network.check $(T)/volumes.check
	@$(if $(xqRunning),,$(xqRun) && sleep 3)
	@$(if $(xqRunning),docker ps --all --filter name=$(XQ) --format ' -  $(XQ) container status [ {{.Status}} ]',)

.PHONY: down
down: 
	@$(if $(xqRunning),echo -n ' - stopping container: ' && docker stop $(XQ),)

$(T)/network.check:
	@#echo '##[ $@ ]##'
	@docker network list --format '{{.Name}}' > $@
	@grep -oP '^$(NETWORK)' $@ &>/dev/null || docker network create $(NETWORK)



MustHaveVolume = docker volume list --format "{{.Name}}" | \
 grep -q $(1) || docker volume create --driver local --name $(1) &>/dev/null

$(T)/volumes.check:
	@# might as well check proxy volumes as well
	@docker volume list  --format "{{.Name}}" > $@
	@$(call MustHaveVolume,xqerl-compiled-code)
	@$(call MustHaveVolume,xqerl-database)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,letsencrypt)
	@$(call MustHaveVolume,site-lualib)
	@docker volume list  --format "{{.Name}}" > $@

.PHONY: info
info: run
	@echo '## $@ ##'
	@docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}'
	@docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'
	@echo -n '-    port: '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})'
	@echo -n '- IP address: '
	@docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
	@echo;printf %60s | tr ' ' '-' && echo
	@echo -n '- working dir: '
	@$(EVAL) '{ok,CWD}=file:get_cwd(),list_to_atom(CWD).'
	@echo -n '-        node: '
	@$(EVAL) 'erlang:node().'
	@#$(EVAL) 'erlang:nodes().' 
	@echo -n '-      cookie: '
	@$(EVAL) 'erlang:get_cookie().'
	@echo -n '-        host: '
	@$(EVAL) '{ok, HOSTNAME } = net:gethostname(),list_to_atom(HOSTNAME).'
	@echo;printf %60s | tr ' ' '-' && echo
	@$(EVAL) $(compiledLibs)



######################
###  STATIC ASSETS ###
######################


.PHONY: assets
assets: $(D)/static-assets.tar

.PHONY: clean-assets
clean-assets: clean-icons clean-styles
	@echo '## $@ ##'
	@rm -f $(D)/static-assets.tar

$(D)/static-assets.tar: icons styles
	@echo '## $@ ##'
	@# after all assets built copy into the static-assets volume
	@docker run --rm \
 --mount $(MountAssets) \
 --mount $(MountBuild) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -rv /tmp/$(DOMAIN) $(OPENRESTY_HOME)/nginx/html/'
	@rm -f $(D)/static-assets.tar
	# tar the static-assets volume to ready for deployment
	@docker run --rm \
 --mount $(MountAssets) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) czf - $(OPENRESTY_HOME)/nginx/html  > $@

.PHONY: remove-content-in-assets-volume
remove-content-in-assets-volume:
	@echo '## $@ ##'
	@docker run --rm \
 --mount $(MountAssets) \
 --entrypoint "rm" $(PROXY_DOCKER_IMAGE) -rf ./nginx/html/$(DOMAIN)


#############
### ICONS ###
#############

BuildIconsList := $(patsubst  %.svg,$(B)/$(DOMAIN)/%.svgz,$(wildcard resources/icons/*.svg))

.PHONY: icons
icons: $(BuildIconsList)

.PHONY: clean-icons 
clean-icons:
	@echo '## $@ ##'
	@rm -f $(BuildIconsList)
	@rm -fr $(T)/*

$(T)/$(DOMAIN)/resources/icons/%.svg: resources/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use scour to clean and optimize SVG'
	@cat $< | docker run \
  --rm \
  --name scour \
  --interactive \
docker.pkg.github.com/grantmacken/alpine-scour/scour:0.0.2 >  $@

$(B)/$(DOMAIN)/resources/icons/%.svgz: $(T)/$(DOMAIN)/resources/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use zopfli to compress image'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo " orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"

######################################
### STYLES: CASCADING STYLE SHEETS ###
######################################

BuildStylesList := $(patsubst %.css,$(B)/$(DOMAIN)/%.css.gz,$(wildcard resources/styles/*.css))

.PHONY: styles
styles: $(BuildStylesList)

.PHONY: clean-styles
clean-styles:
	@echo '## $@ ##'
	@rm -f $(BuildStylesList)
	@rm -fr $(T)/*

$(T)/$(DOMAIN)/resources/styles/%.css: resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@echo  ' - use cssnano to reduce css file size'
	@cat $< | docker run \
  --rm \
  --init \
  --name cssnano \
  --interactive \
   docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 > $@

$(B)/$(DOMAIN)/resources/styles/%.css.gz: $(T)/$(DOMAIN)/resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@echo  ' - use zopfli to gzip file'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo "orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "cssnano size: [ $$(wc -c $(T)/$(DOMAIN)/resources/styles/$*.css | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"


