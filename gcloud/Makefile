SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include ../.env
B := .build
D :=  ../deploy
$(shell mkdir -p ./{$(B),$(D)})

#########################
#  GCLOUD DEPLOYMENT  ###
# NOTE: xqerl compile order is important
# Must match local dev ModuleList
# ModuleList := newBase60 render_feed render_login render_note routes
##########################

define xqOrderedCompile
'xqerl eval \
"xqerl:compile(\"code/src/newBase60.xqm\"),\
xqerl:compile(\"code/src/render_feed.xqm\"),\
xqerl:compile(\"code/src/render_login.xqm\"),\
xqerl:compile(\"code/src/render_note.xqm\"),\
xqerl:compile(\"code/src/routes.xqm\")."'
endef

XQ := $(XQERL_CONTAINER_NAME)
NGX := $(PROXY_CONTAINER_NAME)
xqVolumeList  := xqerl-compiled-code xqerl-database
orVolumeList  := nginx-configuration  static-assets
# NOTE: 'letsencrypt' volume is populated by certbot
ModuleList  := newBase60 render_feed render_note micropub routes
Gcmd := gcloud compute ssh $(GCE_NAME) --command
Gxq := gcloud compute ssh $(GCE_NAME) --container $(XQ) --command
Gngx  := gcloud compute ssh $(GCE_NAME) --container $(NGX) --command
#  xqerl volumes
mountData   := type=volume,target=$(XQERL_HOME)/data,source=xqerl-database
mountCode   := type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
#  proxy volumes
mountNginxConf   := type=volume,target=$(PROXY_HOME)/conf,source=nginx-configuration
mountNginxHtml   := type=volume,target=$(PROXY_HOME)/html,source=static-assets
mountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
# the bind mount on GCE host
mountDeploy := type=bind,target=/tmp,source=/home/$(GCE_NAME)/deploy
tarList := $(wildcard *.tar)

# proxy env vars
# GH_ClIENT_ID     := $(shell cat ../../.ghClientID)
# GH_ClIENT_SECRET := $(shell cat ../../.ghClientSecret)

# Default - top level rule is what gets ran when you run just `make`
.PHONY: build-xqerl
build-xqerl: $(B)/xqerl-compile.complete

#$(B)/proxy-up
.PHONY: clean
clean:
	@find $(B)/ -type f | xargs rm -f

.PHONY: down
down: 
	@$(Gcmd) 'docker stop $(PROXY_CONTAINER_NAME)'
	@$(Gcmd) 'docker stop $(XQERL_CONTAINER_NAME)'

.PHONY: tars-into-gce-host
tars-into-gce-host: $(B)/tars-into-gce-host.moved

.PHONY: compiled-code-volume
compiled-code-volume: $(B)/xqerl-compiled-code.volume

.PHONY: xqerl-compile-code
xqerl-compile-code: $(B)/xqerl-compile.complete

.PHONY: static-assets-volume
static-assets-volume: $(B)/static-assets.volume

.PHONY: nginx-configuration-volume
nginx-configuration-volume: $(B)/nginx-configuration.volume

PHONY: nginx-configuration-test
nginx-configuration-test: $(B)/nginx-configuration.tested

PHONY: proxy-reload
proxy-reload: $(B)/proxy.reloaded

PHONY: proxy-up
proxy-up: $(B)/proxy.up

PHONY: volumes-check
volumes-check: $(B)/volumes.checked

PHONY: proxy-down
proxy-down:
	@$(Gcmd) 'docker stop $(NGX)'

###########################################################################

$(B)/xqerl-compile.complete: $(B)/xqerl-compiled-code.volume $(B)/xqerl.up
	@echo '##[ $@ ]##'
	@$(Gxq) $(xqOrderedCompile)
	@$(Gxq)  \
 'xqerl eval "lists:sort([binary_to_list(X) || X <- xqerl_code_server:library_namespaces()])"'  | tee $@
	@printf %60s | tr ' ' '-' && echo
	@echo ' - xqerl xquery code compiled'
	@printf %60s | tr ' ' '-' && echo

# XQERL VOLUME
##############

$(B)/xqerl-compiled-code.volume: $(B)/tars-into-gce-host.moved $(D)/xqerl-compiled-code.tar
	@echo '##[ $@ ]##'
	@# extract tar into volume
	@$(Gcmd) 'docker run --rm \
 --mount $(mountCode) \
 --mount $(mountDeploy) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) xvf /tmp/xqerl-compiled-code.tar -C /' | tee $(@)
	@printf %60s | tr ' ' '-' && echo
	@echo ' - xqerl-compiled-code volume commited '
	@printf %60s | tr ' ' '-' && echo

# PROXY VOLUMES
################

$(B)/nginx-configuration.volume: $(B)/tars-into-gce-host.moved $(D)/nginx-configuration.tar
	@# extract tar into volume
	@$(Gcmd) 'docker run --rm \
 --mount $(mountNginxConf) \
 --mount $(mountDeploy) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/nginx-configuration.tar -C /' | tee $(@)
	@# should be able to do more test and any failure will remove nginx-configuration.volume
	@# should be able to create backup restore points by creating a date-time stamp
	@printf %60s | tr ' ' '-' && echo
	@echo ' - /nginx-configuration.tar extracted into the docker nginx-configuration volume'
	@printf %60s | tr ' ' '-' && echo

$(B)/static-assets.volume: $(B)/tars-into-gce-host.moved $(D)/static-assets.tar
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker run --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountDeploy) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/static-assets.tar -C /' | tee $(@)
	@printf %60s | tr ' ' '-' && echo
	@echo ' - static-assets.tar extracted into static-assets volume'
	@printf %60s | tr ' ' '-' && echo

# TARS MOVED INTO GEC HOST
##########################

$(B)/tars-into-gce-host.moved: $(B)/gce-deploy.cleaned
	@gcloud compute scp $(D) $(GCE_NAME):~/ --recurse
	$(Gcmd) 'ls -al deploy' | tee $@
	@printf %60s | tr ' ' '-' && echo

$(B)/gce-deploy.cleaned:
	@echo '##[ $@ ]##'
	@$(Gcmd) 'rm -fv deploy/*' | tee $@
	@printf %60s | tr ' ' '-' && echo

define ngxRun
docker run --rm \
 --mount $(mountNginxConf) \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --name  $(NGX) \
 --hostname nginx \
 --network $(NETWORK) \
 --publish 80:80 \
 --publish 443:443 \
 --detach \
 $(PROXY_DOCKER_IMAGE)
endef

# PROXY
#######

$(B)/proxy.up: $(B)/nginx-configuration.tested
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(NGX) --format "{{.Status}}" | grep -q Up || $(ngxRun)'
	@sleep 2
	@$(Gcmd) 'docker ps --filter name=$(NGX) --format "{{.Names}} {{.Status}} "' | tee $@

$(B)/nginx-configuration.tested: $(B)/nginx-configuration.volume $(B)/static-assets.volume
	@# test configuration with dummy proxy
	@$(Gcmd) 'docker run --rm \
 --mount $(mountNginxConf) \
 --mount $(mountLetsencrypt) \
 --mount $(mountNginxHtml) \
 --network $(NETWORK) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c "./sbin/nginx -t"' | tee $(@)
	@printf %60s | tr ' ' '-' && echo
	@echo ' - nginx configuration tested using dummy container instance'
	@printf %60s | tr ' ' '-' && echo

$(B)/proxy.reloaded: $(B)/proxy.up
	@# test configuration with dummy proxy
	@$(Gngx) './sbin/nginx -s reload'
	@printf %60s | tr ' ' '-' && echo

# XERL runs before PROXY
########################

$(B)/xqerl.up: $(B)/volumes.checked
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(XQ) --format "{{.Status}}" | grep -q Up || \
 docker run \
 --rm \
 --mount $(mountCode) \
 --mount $(mountData) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach $(XQERL_DOCKER_IMAGE)'
	@sleep 2
	@$(Gcmd) 'docker ps --filter name=$(XQ) --format "{{.Names}} {{.Status}} "' | tee $@

$(B)/volumes.checked: $(B)/volumes.list
	@mkdir -p $(dir $@)
	@grep -oP 'letsencrypt' $< &>/dev/null || $(Gcmd) 'docker volume create --driver local --name letsencrypt'
	@grep -oP 'nginx-configuration' $<  &>/dev/null|| $(Gcmd) 'docker volume create --driver local --name nginx-configuration'
	@grep -oP 'static-assets' $< &>/dev/null || $(Gcmd) 'docker volume create --driver local --name static-assets'
	@grep -oP 'xqerl-compiled-code' $< &>/dev/null || $(Gcmd) 'docker volume create --driver local --name xqerl-compiled-code'
	@grep -oP 'xqerl-database' $< &>/dev/null || $(Gcmd) 'docker volume create --driver local --name xqerl-database'
	@printf %60s | tr ' ' '-' && echo
	@echo ' - docker volume list on GCE host'
	@$(Gcmd) 'docker volume list --format "{{.Name}}"' | tee $@
	@printf %60s | tr ' ' '-' && echo

$(B)/volumes.list:
	@mkdir -p $(dir $@)
	@$(Gcmd) 'docker volume list --format "{{.Name}}"' > $@
	@printf %60s | tr ' ' '-' && echo

###############
### UTILITY ###
###############

.PHONY: xq-down
xq-down:
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(XQ) --format '{{.Status}}' | grep -q Up && docker stop $(XQ)'
	@$(Gcmd) 'docker ps --all --filter name=$(XQ) --format '{{.Status}}' | grep -q Exited && docker rm $(XQ)'
	@$(Gcmd) 'docker  ps --all'

xq-info:
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(XQ) --format "name: {{.Names}}"'
	@$(Gcmd) 'docker ps --filter name=$(XQ) --format "status: {{.Status}}"'
	@echo -n '- IP address: '
	@$(Gcmd) 'docker inspect --format="{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}" $(XQ)'
	@echo;printf %60s | tr ' ' '-' && echo
	@echo -n '- working dir: '
	@$(Gxq) 'xqerl eval "{ok,CWD}=file:get_cwd(),list_to_atom(CWD)."'
	@echo -n '-        node: '
	@$(Gxq) 'xqerl eval "erlang:node()."'
	@echo -n '-      cookie: '
	@$(Gxq) 'xqerl eval "erlang:get_cookie()."'
	@echo -n '-        host: '
	@$(Gxq) 'xqerl eval "{ok, HOSTNAME } = net:gethostname(),list_to_atom(HOSTNAME)."'

xq-libs:
	@$(Gxq)  'xqerl eval "lists:sort([binary_to_list(X) || X <- xqerl_code_server:library_namespaces()])"'
