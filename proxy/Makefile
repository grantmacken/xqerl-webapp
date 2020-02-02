SHELL=/bin/bash
include $(abspath ../.env)

OR := $(PROXY_CONTAINER_NAME)
XQ := $(XQERL_CONTAINER_NAME)

T := .tmp
B := .build
D := .deploy

DEO  = docker exec $(OR)

dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP '$(NETWORK)'
dkrPortInUse    != docker ps --format '{{.Ports}}' | grep -oP '^(.+)443->\K(443)'
dkrStatusUp     != docker ps --filter name=$(OR) --format '{{.Status}}' | grep -oP '^Up.+$$'
xqStatusUp      != docker ps --filter name=$(XQ) --format '{{.Status}}' | grep -oP '^Up.+$$'

###########################
### NGINX CONFIGURATION ###
###########################

define mkCertsConf
# My LETSENCRYPT certs
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
endef

VolumeList  := nginx-configuration static-assets letsencrypt site-lualib
mountNginxConf   := type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration
mountNginxHtml   := type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets
mountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
mountSiteLualib  := type=volume,target=$(OPENRESTY_HOME)/site/lualib,source=site-lualib
mountBuild       := type=bind,target=/tmp,source=$(CURDIR)/$(B)

dkrTarRun  := docker run --rm --mount $(mountNginxConf)
dkrCpRun   := docker run --rm --mount $(mountNginxConf) --mount $(mountBuild) 
dkrRun     := docker run  \
 --mount $(mountNginxConf) \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --mount $(mountSiteLualib) \
 --name  $(PROXY_CONTAINER_NAME) \
 --network $(NETWORK) \
 --publish 80:80 \
 --publish 443:443 \
 --detach \
 $(PROXY_DOCKER_IMAGE)



buildConfs := $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))

.PHONY: conf
conf: $(D)/nginx-configuration.tar

.PHONY: clean-conf
clean-conf:
	@echo '## $(@) ##'
	@rm -f $(buildConfs)
	@rm -f $(D)/nginx-configuration.tar

$(D)/nginx-configuration.tar: build
	@mkdir -p $(dir $@)
	@echo ' - tar the "nginx-confguration" volume into deploy directory' 
	@$(dkrTarRun) --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(OPENRESTY_HOME)/nginx/conf > $@

.PHONY: build
build: certs confs
	@echo ' - build complete ... '
	@echo ' - copy build files into "nginx-confguration" volume'
	@$(dkrCpRun) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -r /tmp/nginx ./ '

.PHONY: confs
confs: $(buildConfs)

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkCertsConf}" > $@

$(B)/nginx/conf/%: conf/%
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	$(if $(LOCAL_RELOAD),echo ' - local reload: $(LOCAL_RELOAD)',)
	@$(if $(LOCAL_RELOAD),$(dkrCpRun) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp  /tmp/nginx/conf/$(*) ./nginx/conf/',)
	@$(if $(LOCAL_RELOAD),$(DEO) ./bin/openresty -t,) 
	@$(if $(LOCAL_RELOAD),$(DEO) ./bin/openresty -s reload,) 
	@cp $< $@

.PHONY: watch-confs
watch-confs:
	@while true; do \
        $(MAKE) --silent confs LOCAL_RELOAD=yep ; \
        inotifywait -qre close_write . ; \
    done

#######################
# GCLOUD DEPLOYMENT ###
#######################
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(XQ) --command 

.PHONY: gcloud-conf-volume-deploy
gcloud-conf-volume-deploy: $(D)/nginx-configuration.tar
	@# make sure we have a deploy directory on the host
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@# copy into GCE host
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@#gcloud compute ssh $(GCE_NAME) --command  'ls -al ./deploy'
	@# extract tar into volume
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(mountNginxConf) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'

GcloudVolumeCreate = grep -q $(1) $(2) || $(Gcmd) 'docker volume create --driver local --name $(1)'

.PHONY: gcloud-check-volumes
gcloud-check-volumes: $(D)/gcloud-volume-check.txt
	@$(foreach volume,$(VolumeList),$(call GcloudVolumeCreate,$(volume),$(<)))

$(D)/gcloud-volume-check.txt: 
	@mkdir -p $(dir $@)
	@$(Gcmd) 'docker volume list  --format "{{.Name}}"' > $@

.PHONY: gcloud-proxy-up
gcloud-proxy-up: 
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(OR) --format "{{.Status}}"' | grep -q Up || $(Gcmd) '$(dkrRun)'
	@sleep 2
	@$(Gcmd) 'docker ps --filter name=$(OR) --format "{{.Status}}"'
	@$(Gcmd) 'docker logs $(OR)'

#########################
### LETSENCRYPT CERTS ###
#########################


.PHONY: certsToHost
certsToHost: $(B)/certs/letsencrypt.tar
	@echo ' - on local host extract letsencrypt.tar into "letsencypt" volume' 
	@docker run --rm \
 --mount $(mountLetsencrypt) \
 --mount type=bind,target=/tmp,source=$(CURDIR)/$(dir $<) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /
	@rm -fr $(dir $<)

$(B)/certs/letsencrypt.tar: check-volumes
	@echo ' - on GCE host tar "$(OR)" volume into host dir' 
	@$(Gcmd) 'docker run --rm --volumes-from $(OR) \
 --mount type=bind,target=/home,source=/home/$(GCE_NAME)/certs \
 alpine:3.11 tar -czf /home/letsencrypt.tar $(LETSENCRYPT)'
	@echo -n ' - fetching tar from GCE host to local host: '  
	@gcloud compute scp $(GCE_NAME):~/certs ./ --recurse
	@mv certs $(B)/


.PHONY: hostsFile
hostsFile:
	@echo '## $@ ##'
	# adjust hosts file TODO all domains
	@echo "127.0.0.1  $(TLS_COMMON_NAME)" | sudo tee -a /etc/hosts
	@cat /etc/hosts
	@printf %60s | tr ' ' '-' && echo


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


#######################
### UTILITY TARGETS ###
#######################
MustHaveVolume = docker volume list --format "{{.Name}}" | grep -q $(1) || docker volume create --driver local --name $(1)

.PHONY: check-volumes
check-volumes: $(T)/volume-check.txt
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,letsencrypt)
	@$(call MustHaveVolume,site-lualib)
	@docker volume list  --format "{{.Name}}"
	@echo "[ $(VolumeList) ] OK! all volumes available"

$(T)/volume-check.txt: 
	@mkdir -p $(dir $@)
	@docker volume list  --format "{{.Name}}" > $@

.PHONY: check-network
check-network:
	@echo -n ' - $@  '
	@$(if $(dkrNetworkInUse),echo  '[ $(NETWORK) ] OK! can use ',docker network create $(NETWORK))

.PHONY: check-port
check-port:
	@echo -n ' - check TLS port '
	@$(if $(dkrPortInUse), echo '[  $(dkrPortInUse) ] is already taken';false , echo  '[ 443 ] OK! can use.')

.PHONY: up
up: check-volumes check-network check-port
	@echo -n ' - start container instance '
	@$(if $(dkrStatusUp), echo '[ already running ] ',echo '[ $(OR) ]')
	@$(if $(dkrStatusUp),false,true)
	@echo ' - check "$(XQ)" status [ $(xqStatusUp) ]'
	@$(if $(xqStatusUp),true,false)
	@echo 'TODO - check letsencypt certs in "letsencrypt" volume'
	@$(dkrRun)

.PHONY: down
down: 
	@echo '##[ $@ ]##'
	@$(if $(dkrStatusUp),echo -n ' - stopping: ' && docker stop $(OR) , echo '- already stopped')
	@sleep 2
	@docker container list --all --filter name=$(OR) | grep -q Exited  && echo -n ' - removing: ';docker rm $(OR)
