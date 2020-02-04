SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include ../.env
T := .tmp
B := .build
D :=  ../deploy
#########################
#  GCLOUD DEPLOYMENT  ###
##########################

XQ := $(XQERL_CONTAINER_NAME)
OR := $(PROXY_CONTAINER_NAME)
xqVolumeList  := xqerl-compiled-code xqerl-database
orVolumeList  := nginx-configuration  static-assets 
# NOTE: 'letsencrypt' volume is populated by certbot
# NOTE: site-lualib not yet implemented
ModuleList  := newBase60 render_feed render_note micropub routes
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(XQ) --command 
Gor  := gcloud compute ssh $(GCE_NAME) --container $(OR) --command 
#  xqerl volumes
mountData   := type=volume,target=$(XQERL_HOME)/data,source=xqerl-database
mountCode   := type=volume,target=$(XQERL_HOME)/code,source=xqerl-compiled-code
#  proxy volumes
mountNginxConf   := type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration
mountNginxHtml   := type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets
mountSiteLualib  := type=volume,target=$(OPENRESTY_HOME)/site/lualib,source=site-lualib
mountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
# the bind mount on GCE host
mountDeploy := type=bind,target=/tmp,source=/home/$(GCE_NAME)/deploy
tarList := $(wildcard *.tar)

# Default - top level rule is what gets ran when you run just `make`
.PHONY: build
build: $(B)/xqerl-compile.complete

.PHONY: clean
clean:
	@rm -fr $(B)/*

.PHONY: proxy
proxy: $(D)/nginx-configuration.volume
	@echo '##[ $@ ]##'
	@$(Gor) 'bin/openresty -t' 
	@$(Gor) 'bin/openresty -s reload'

$(B)/nginx-configuration.volume: $(D)/nginx-configuration.tar
	@mkdir -p $(dir $@)
	@# extract tar into volume
	@$(Gcmd) 'docker run --rm \
 --mount $(mountNginxConf) \
 --mount $(mountDeploy) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/nginx-configuration.tar -C /' | tee $(@)
	@# should be able to do more test and any failure will remove nginx-configuration.volume
	@# should be able to create backup restore points by creating a date-time stamp
	@printf %60s | tr ' ' '-' && echo

$(B)/static-assets.volume: $(D)/static-assets.tar
	@mkdir -p $(dir $@)
	@# extract tar into volume
	@$(Gcmd) 'docker run --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountDeploy) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/static-assets.tar -C /' | tee $(@)
	@printf %60s | tr ' ' '-' && echo


# $(B)/volumes.checked
# this is call from github action but may be called locally
# newBase60 render_feed render_note micropub routes
$(B)/xqerl-compile.complete: $(B)/xqerl-compiled-code.volume $(B)/xqerl.up
	@echo '##[ $@ ]##'
	@$(GCmd) 'xqerl eval \
"xqerl:compile(\"code/src/newBase60.xqm\"),\
xqerl:compile(\"code/src/render_feed.xqm\"),\
xqerl:compile(\"code/src/render_feed.xqm\"),\
xqerl:compile(\"code/src/routes.xqm\")."'
	@$(GCmd)  \
 'xqerl eval "lists:sort([binary_to_list(X) || X <- xqerl_code_server:library_namespaces()])"'  | tee $@

$(B)/xqerl-compiled-code.volume: $(B)/tars-into-gce-host.moved
	@mkdir -p $(dir $@)
	@# extract tar into volume
	@$(Gcmd) 'docker run --rm \
 --mount $(mountCode) \
 --mount $(mountDeploy) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) xvf /tmp/xqerl-compiled-code.tar -C /' | tee $(@)

$(B)/tars-into-gce-host.moved: 
	@$(Gcmd) 'rm -fr ./deploy' 
	@gcloud compute scp $(D) $(GCE_NAME):~/ --recurse
	$(Gcmd) 'ls -al deploy' | tee $@
	@printf %60s | tr ' ' '-' && echo

$(B)/volumes.checked: $(B)/volumes.list
	@mkdir -p $(dir $@)
	@grep -oP 'letsencrypt' $< || $(Gcmd) 'docker volume create --driver local --name letsencrypt' 
	@grep -oP 'nginx-configuration' $< || $(Gcmd) 'docker volume create --driver local --name nginx-configuration' 
	@grep -oP 'site-lualib' $< || $(Gcmd) 'docker volume create --driver local --name site-lualib' 
	@grep -oP 'static-assets' $< || $(Gcmd) 'docker volume create --driver local --name static-assets'
	@grep -oP 'xqerl-compiled-code' $< || $(Gcmd) 'docker volume create --driver local --name xqerl-compiled-code'
	@grep -oP 'xqerl-database' $< || $(Gcmd) 'docker volume create --driver local --name xqerl-database'
	@$(Gcmd) 'docker volume list --format "{{.Name}}"' | tee $@
	@grep -oP 'letsencrypt' $@
	@grep -oP 'nginx-configuration' $@
	@grep -oP 'site-lualib' $@
	@grep -oP 'static-assets' $@
	@grep -oP 'xqerl-compiled-code' $@
	@grep -oP 'xqerl-database' $@
	@printf %60s | tr ' ' '-' && echo

$(B)/volumes.list:
	@mkdir -p $(dir $@)
	@$(Gcmd) 'docker volume list --format "{{.Name}}"' | tee $@
	@printf %60s | tr ' ' '-' && echo
	@#cat $@

.PHONY: proxy-up
proxy-up:
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(OR) --format "{{.Status}}" | grep -q Up || \
 docker run  \
 --mount $(mountNginxConf) \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --mount $(mountSiteLualib) \
 --name  $(OR) \
 --hostname openresty \
 --network $(NETWORK) \
 --publish 80:80 \
 --publish 443:443 \
 --detach \
 $(PROXY_DOCKER_IMAGE)'
	@sleep 2
	@$(Gcmd) 'docker ps --filter name=$(OR)'

$(B)/xqerl.up: $(B)/volumes.checked
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(XQ) --format "{{.Status}}" | grep -q Up || \
 docker run \
 --mount $(mountCode) \
 --mount $(mountData) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach $(XQERL_DOCKER_IMAGE)' 
	@sleep 2
	@$(Gcmd) 'docker ps --filter name=$(XQ) --format "{{.Names}} {{.Status}} "' | tee $@

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
	@$(GCmd) 'xqerl eval "{ok,CWD}=file:get_cwd(),list_to_atom(CWD)."'
	@echo -n '-        node: '
	@$(GCmd) 'xqerl eval "erlang:node()."'
	@echo -n '-      cookie: '
	@$(GCmd) 'xqerl eval "erlang:get_cookie()."'
	@echo -n '-        host: '
	@$(GCmd) 'xqerl eval "{ok, HOSTNAME } = net:gethostname(),list_to_atom(HOSTNAME)."'

xq-libs:
	@$(GCmd)  'xqerl eval "lists:sort([binary_to_list(X) || X <- xqerl_code_server:library_namespaces()])"'

