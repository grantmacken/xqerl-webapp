SHELL=/bin/bash
include $(abspath ../.env)

OR=$(PROXY_CONTAINER_NAME)

T := .tmp
B := .build
D := .deploy
COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DELIMIT := $(COMMA)$(EMPTY)
DEO  = docker exec $(OR)
include ./.inc/*

 ### NGINX CONFIGURATION
##############################

define help-nginx-configuration

produces: a docker volume containing my nginx configuration
used by:  running openresty container
-----------------------------------------------------------
Make targets
conf-build - build nginx conf files a copies them into a 
             docker volume named `nginx-configuration`


conf-deploy
 1. create 'tar' of the built `nginx-configuration` volume
 2. use 'gcloud' to secure copy 'tar' into GCE host
 3. use 'gcloud` to extract tar into GCE host docker volume named 'nginx-configuration'

 nginx configuration is now on GCE host as a *docker volume*,
 however it will not be live until we *restart* nginx

NOTE these actions should be able to be performed locally and by 
     github actions

endef

define mkCertsConf
# My LETSENCRYPT certs
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
endef

# build 

.PHONY: conf-build
conf-build: certs confs
	@echo '## $(@) ##'
	@docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
 --mount type=bind,target=/tmp,source=$(CURDIR)/$(B) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -rv /tmp/nginx ./ '
	@$(if $(GITHUB_ACTIONS),,$(DEO) ./bin/openresty -t )
	@$(if $(GITHUB_ACTIONS),,$(DEO) ./bin/openresty -s reload)

.PHONY: confs
confs: $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkCertsConf}" > $@
	@#$(if $(GITHUB_ACTIONS),docker cp $@ $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@) )

$(B)/nginx/conf/%: conf/%
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@#$(if $(GITHUB_ACTIONS),,docker cp $@ $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@))
	@cp $< $@

# deploy 
##########

.PHONY: conf-deploy
conf-deploy: $(D)/nginx-configuration.tar
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@gcloud compute ssh $(GCE_NAME) --command  'ls -al ./deploy'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=static-assets \
 --entrypoint "ls" $(PROXY_DOCKER_IMAGE) -alR ./nginx/conf' 

$(D)/nginx-configuration.tar:
	@mkdir -p $(dir $@)
	echo '## $@ ##'
	@docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(OPENRESTY_HOME)/nginx/conf > $@

.PHONY: clean-conf
clean-conf:
	@echo '## $(@) ##'
	@rm -rf  $(B)/nginx/conf

 ### REPO OWNERS LUALIBS
##############################
# TODO mount at site/lualib not site/lualib/$(REPO_OWNER)

RelPathLibs := site/lualib/$(REPO_OWNER)
MountLibs :=  type=volume,target=$(OPENRESTY_HOME)/$(RelPathLibs),source=repo-owners-lualibs

.PHONY: libs  
libs: $(patsubst lualib/%.lua,$(B)/$(RelPathLibs)/%.lua, $(wildcard lualib/*))
	@echo '## $(@) $(CURDIR)  ##'
	@docker run --rm \
 --mount $(MountLibs) \
 --mount type=bind,target=/tmp,source=$(CURDIR)/$(B) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -rv /tmp/site ./ '

$(B)/site/lualib/$(REPO_OWNER)/%.lua: lualib/%.lua
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@# docker cp $< $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@)
	@cp $<  $@

.PHONY: site-lualib-volume
site-lualib-volume: $(D)/site-lualib.tar
	gcloud compute scp $< $(GCE_NAME):~/deploy
	@gcloud compute ssh $(GCE_NAME) --command  'ls -al ./deploy'

$(D)/site-lualib.tar:
	@mkdir -p $(dir $@)
	echo '## $@ ##'
	@docker run --rm \
 --mount type=volume,target=,source=$(OPENRESTY_HOME)/site/lualib \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - ./ > $@

PHONY: clean-libs
clean-libs:
	@echo '## $(@) ##'
	@rm -rf $(B)/site
	@#$(DEO) rm -fr site/lualib/$(REPO_OWNER)
	@$(DEO) mkdir -p site/lualib/$(REPO_OWNER)

.PHONY: certs 
certs: $(B)/nginx/conf/certs.conf

.PHONY: or-restart
or-restart:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec or ./bin/openresty -t
	@echo ' - local restart'
	@#docker exec or kill -HUP 1
	@docker exec or ./bin/openresty -s reload
	@#docker exec or openresty start
	@#docker ps | grep 'openresty'

.PHONY: or-test
or-test:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec -t or openresty -t





