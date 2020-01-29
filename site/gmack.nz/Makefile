SHELL=/bin/bash
include ../../.env
DOMAIN = gmack.nz
T := .tmp
B := .build
D := .deploy
# shortcut aliases
XQ := $(XQERL_CONTAINER_NAME)
DEX := docker exec $(XQ)
ESCRIPT := $(DEX) xqerl escript
EVAL := $(DEX) xqerl eval
OR := $(PROXY_CONTAINER_NAME)
DEO := docker exec $(OR)
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"
# mpURL := https://$(DOMAIN)/micropub
# mpJSON := $(mpURL) -H 'Content-Type: application/json' 
xqIPAddress = $(shell  docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ))
xqStatus != docker ps --filter name=$(XQ) --format '{{.Status}}'
xqPortInUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+)8081->\K(8081)'
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
ModuleList := newBase60 render-feed render-note micropub routes
BuildList := $(patsubst %,$(B)/modules/%.xqm,newBase60 render-feed render-note micropub routes)
DeployList := $(patsubst %,$(D)/modules/%.xqm,newBase60 render-feed render-note micropub routes)

MountCode :=  type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
MountData :=  type=volume,target=$(XQERL_HOME)/data,source=xqerl-database

.PHONY: xqerl-compiled-code
xqerl-compiled-code: $(D)/xqerl-compiled-code.tar 



$(D)/xqerl-compiled-code.tar: $(BuildList)
	echo '## $(notdir $@) ##'
	@mkdir -p $(dir $@)
	@docker run --rm \
 --mount $(MountCode) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) -czf - $(XQERL_HOME)/code &>/dev/null > $@

.PHONY: clean-site
clean-site:
	@echo '##[ $@ ]##'
	@rm -f $(B)/modules/*

$(B)/modules/%.xqm: modules/%.xqm
	@echo '##[ $* ]##'
	@mkdir -p $(dir $@)
	@rm -fr $(T)/*
	@docker cp $(<) $(XQ):$(XQERL_HOME)/code/src
	@$(call compile,$(notdir $<)) | tee $(T)/compile_$(*).txt
	@cat $(T)/compile_$(*).txt | grep -q ':I:'
	@#$(DEX) rm -f $(CODE_SRC)/$(notdir $<)
	@$(DEX) ls $(XQERL_HOME)/code/src
	@cp $< $@
	@echo;printf %60s | tr ' ' '-' && echo
	@$(EVAL) $(compiledLibs)
	@echo;printf %60s | tr ' ' '-' && echo

# this is call from github action but may be called locally
.PHONY: code-deploy
code-deploy: $(D)/xqerl-compiled-code.tar
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(MountCode) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'

# this is called when xqerl is running
# not sure why I have to do this as code is already compiled

.PHONY: code-compile
code-compile: $(D)/xq-status.txt $(DeployList)

$(D)/xq-status.txt:
	@gcloud compute ssh $(GCE_NAME) --command 'docker ps --filter name=$(XQ) --format "xqerl {{.Status}}"' > $(T)/xq-status.txt
	@if [ -s $(T)/xq-status.txt ] ; then cat $(T)/xq-status.txt; else $(MAKE) xqerl-run ; fi

$(D)/modules/%.xqm: $(B)/modules/%.xqm
	@echo '##[ $* ]##'
	@mkdir -p $@
	@gcloud compute ssh $(GCE_NAME) \
 --container '$(XQ)' \
 --command \
 'xqerl eval "xqerl:compile(\"code/src/$(notdir $@)\")"'
	@cp $< $@

PHONY: clean-code
clean-code: 
	@echo "## $(@) ##"
	@rm -fv $(wildcard $(B)/modules/*)


PHONY: clean
clean: 
	@echo "## $(@) ##"
	@rm -rfv $(B)

.PHONY: xqerl-run
xqerl-run: 
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker  run \
 --mount $(MountCode) \
 --mount $(MountData) \
 --name  $(XQERL_CONTAINER_NAME) \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_DOCKER_IMAGE)'
	@sleep 3

### RESOURCES static-assets
##############################

MountAssets :=  type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets

.PHONY: assets-build
assets-build: icons styles
	@docker run --rm \
 --mount $(MountAssets) \
 --mount type=bind,target=/tmp,source=$(CURDIR)/$(B) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -rv /tmp/$(DOMAIN) ./nginx/html/$(DOMAIN)'

.PHONY: remove-assets
remove-assets:
	echo '## $@ ##'
	@docker run --rm \
 --mount MountAssets \
 --entrypoint "rm" $(PROXY_DOCKER_IMAGE) -rf ./nginx/html/$(DOMAIN)

.PHONY: assets-deploy
assets-deploy: $(D)/static-assets.tar
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(MountAssets) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'

$(D)/static-assets.tar:
	echo '## $@ ##'
	@mkdir -p $(dir $@)
	@docker run --rm \
 --mount $(MountAssets) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(OPENRESTY_HOME)/nginx/html > $@

####################################################################
# ICONS
####################################################################

.PHONY: icons
icons: $(patsubst  %.svg,$(B)/$(DOMAIN)/%.svgz,$(wildcard resources/icons/*.svg))

.PHONY: clean-icons
clean-icons:
	@rm -f $(patsubst  %.svg,$(B)/$(DOMAIN)/%.svgz,$(wildcard resources/icons/*.svg))
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
	@echo "   scour size: [ $$(wc -c $(T)/resources/icons/$*.svg | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"

####################################################################
# STYLES: CASCADING STYLE SHEETS
####################################################################

.PHONY: styles
styles: $(patsubst %.css,$(B)/$(DOMAIN)/%.css.gz,$(wildcard resources/styles/*.css))

.PHONY: clean-styles
clean-styles:
	echo '## $@ ##'
	@rm -f $(patsubst %.css,$(B)/$(DOMAIN)/%.css.gz,$(wildcard resources/styles/*.css))
	@rm -fr $(T)/*

$(T)/$(DOMAIN)/resources/styles/%.css: resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use cssnano to reduce css file size'
	@cat $< | docker run \
  --rm \
  --init \
  --name cssnano \
  --interactive \
   docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 > $@

$(B)/$(DOMAIN)/resources/styles/%.css.gz: $(T)/$(DOMAIN)/resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use zopfli to gzip file'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo " orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   cssnano size: [ $$(wc -c $(T)/resources/styles/$*.css | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"





