SHELL=/bin/bash
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
DEO := docker exec $(OR)

xqIPAddress     := docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP '$(NETWORK)'
dkrStatusUp      != docker ps --filter name=$(XQ) --format '{{.Status}}' | grep -oP '^Up.+$$'
dkrPortInUse     != docker ps --format '{{.Ports}}' | grep -oP '^(.+)8081->\K(8081)'

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
BuildList  := $(patsubst %,$(B)/modules/%.xqm,newBase60 render-feed render-note micropub routes)
DeployList := $(patsubst %,$(D)/modules/%.xqm,newBase60 render-feed render-note micropub routes)

VolumeList := xqerl-compiled-code xqerl-database
MountCode  := type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
MountData  := type=volume,target=$(XQERL_HOME)/data,source=xqerl-database
MountBin   := type=bind,target=$(XQERL_HOME)/bin/scripts,source=$(CURDIR)/bin

.PHONY: xqerl-compiled-code
xqerl-compiled-code: $(D)/xqerl-compiled-code.tar

$(D)/xqerl-compiled-code.tar: $(BuildList) 
	@echo '## $(notdir $@) ##'
	@mkdir -p $(dir $@)
	@docker run --rm \
 --mount $(MountCode) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) -czf - $(XQERL_HOME)/code > $@

.PHONY: clean
clean:
	@echo '##[ $@ ]##'
	@rm -f $(B)/modules/*
	@rm -f $(D)/xqerl-compiled-code.tar

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

# GCLOUD DEPLOYMENT
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(XQ) --command 

#  gcloud volumes
GcloudVolumeCreate = grep -q $1 $(2) || $(Gcmd) 'docker volume create --driver local --name $(1)'; 

.PHONY: gcloud-check-volumes
gcloud-check-volumes: $(T)/gcloud-volume-check.txt
	@$(foreach volume,$(VolumeList),$(call GcloudVolumeCreate,$(volume),$(<)))
	@rm -f $<

$(T)/gcloud-volume-check.txt: 
	@mkdir -p $(dir $@)
	@gcloud compute ssh $(GCE_NAME) --command ' docker volume list  --format "{{.Name}}"' > $@

# this is call from github action but may be called locally
.PHONY: gcloud-code-volume-deploy
gcloud-code-volume-deploy: $(D)/xqerl-compiled-code.tar
	@# make sure we have a deploy directory on the host
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@# copy into GCE host
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@# extract tar into volume
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(MountCode) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'

# make sure running

.PHONY: gcloud-xqerl-up
gcloud-xqerl-up:
	@echo '##[ $@ ]##'
	@gcloud compute ssh $(GCE_NAME) --command 'docker ps --filter name=$(OR) --format "{{.Status}}"' | \
 grep -q Up || \
 gcloud compute ssh $(GCE_NAME) --command \
 'docker  run \
 --mount $(MountCode) \
 --mount $(MountData) \
 --name  $(XQERL_CONTAINER_NAME) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_DOCKER_IMAGE)' 
	@sleep 2
	@gcloud compute ssh $(GCE_NAME) --command 'docker ps --filter name=$(OR)'

.PHONY: gcloud-code-compile
gcloud-code-compile: $(DeployList)

# this is called when xqerl is running
# not sure why I have to do this as code is already compiled

$(D)/modules/%.xqm: $(B)/modules/%.xqm
	@echo '##[ $* ]##'
	@mkdir -p $(dir $@)
	@gcloud compute ssh $(GCE_NAME) \
 --container '$(XQ)' \
 --command \
 'xqerl eval "xqerl:compile(\"code/src/$(notdir $@)\")"'
	@cp $< $@

PHONY: gcloud-xqerl-info
gcloud-xqerl-info:
	@echo '## $@ ##'
	@$(Gcmd) \
 "docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}' && docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'"

PHONY:gcloud-show-lib-namespaces
gcloud-show-lib-namespaces:
	@$(GCmd) \
 "xqerl eval 'xqerl_code_server:library_namespaces()'"

######################
###  STATIC ASSETS ###
######################
# 

MountAssets   := type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets
MountBinBuild := type=bind,target=/tmp,source=$(CURDIR)/$(B)

.PHONY: assets
assets: $(D)/static-assets.tar

.PHONY: clean-assets
clean-assets: clean-icons clean-styles
	@echo '## $@ ##'
	@rm -f $(D)/static-assets.tar

$(D)/static-assets.tar: icons styles
	echo '## $@ ##'
	@mkdir -p $(dir $@)
	@# after all assets built copy into the static-assets volume
	@docker run --rm \
 --mount $(MountAssets) \
 --mount $(MountBinBuild) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -rv /tmp/$(DOMAIN) ./nginx/html/$(DOMAIN)'
	@# tar the static-assets volume to ready for deployment
	@docker run --rm \
 --mount $(MountAssets) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(OPENRESTY_HOME)/nginx/html > $@

.PHONY: remove-assets
remove-assets:
	@echo '## $@ ##'
	@docker run --rm \
 --mount MountAssets \
 --entrypoint "rm" $(PROXY_DOCKER_IMAGE) -rf ./nginx/html/$(DOMAIN)

.PHONY: gcloud-assets-volume-deploy
gcloud-assets-volume-deploy: $(D)/static-assets.tar
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(MountAssets) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'


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


#######################
### UTILITY TARGETS ###
#######################

MustHaveVolume = docker volume list --format "{{.Name}}" | grep -q $(1) || docker volume create --driver local --name $(1)

.PHONY: check-volumes
check-volumes:
	@$(call MustHaveVolume,xqerl-compiled-code)
	@$(call MustHaveVolume,xqerl-database)
	@$(call MustHaveVolume,static-assets)
	@docker volume list  --format "{{.Name}}"
	@echo "[ $(VolumeList) ] OK! all volumes available"

.PHONY: check-network
check-network:
	@echo -n ' - $@  '
	@$(if $(dkrNetworkInUse),echo  '[ $(NETWORK) ] OK! can use ',docker network create $(NETWORK))

.PHONY: check-port
check-port:
	@echo ' - $@ '
	@$(if $(dkrPortInUse), echo '- PORT [ $(XQERL_PORT) ] is already taken';false , echo  '- PORT [ $(XQERL_PORT) ] is available')

.PHONY: up
up: check-volumes check-network check-port
	@echo '##[ $@ ]##'
	@$(if $(dkrStatusUp), echo '- already running';false, docker run \
 --mount $(MountCode) \
 --mount $(MountData) \
 --mount $(MountBin) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_DOCKER_IMAGE))
	@sleep 3
	@$(MAKE) -slient info

.PHONY: down
down: 
	@echo '##[ $@ ]##'
	@$(if $(dkrStatusUp),echo -n ' - stopping: ' && docker stop $(XQ) , echo '- already stopped')
	@sleep 2
	@docker container list --all --filter name=$(XQ) | grep -q Exited  && echo -n ' - removing: ';docker rm $(XQ)

PHONY: info
info:
	@echo '## $@ ##'
	@docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}'
	@docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'
	@echo -n '-    port: '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})'
	@echo -n '- IP address: $(xqIPAddress)'
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
