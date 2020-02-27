SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERRNGX:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
LOCAL_RELOAD :=
include ../.env
NGX := $(PROXY_CONTAINER_NAME)
XQ  := $(XQERL_CONTAINER_NAME)
T := .tmp
B := .build
D := ../deploy
$(shell mkdir -p ./{$(T),$(B)/conf,$(D)})
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DOT := .
DEN  = docker exec $(NGX)
Tick  = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1  && echo
FileTick = $(file >$1,$2)$(call Tick,$2)
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo -n $1 && echo
# proxy env vars
# GH_ClIENT_ID     := $(shell cat ../../.ghClientID)
# GH_ClIENT_SECRET := $(shell cat ../../.ghClientSecret)

###########################
### NGINX CONFIGURATION ###
###########################

define mkCertsConf
# My LETSENCRYPT certs
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
endef

# VolumeList  := nginx-configuration static-assets letsencrypt site-lualib
mountNginxConf   := type=volume,target=$(PROXY_HOME)/conf,source=nginx-configuration
mountNginxHtml   := type=volume,target=$(PROXY_HOME)/html,source=static-assets
mountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
mountBuild       := type=bind,target=/tmp,source=$(CURDIR)/$(B)

dkrCpNginxConf   := docker run --rm --mount $(mountNginxConf) --mount $(mountBuild)
dkrTarNginxConf  := docker run --rm --mount $(mountNginxConf)

dkrNginxMountAll := docker run --rm --mount $(mountNginxConf) --mount $(mountNginxHtml) --mount $(mountLetsencrypt)

buildConfs := $(patsubst %,$(B)/%, $(wildcard conf/*))

orAddress  := docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(NGX)

.PHONY: build
build: $(D)/nginx-configuration.tar

.PHONY: clean
clean: clean-tmp
	@echo '## $(@) ##'
	@rm -f $(buildConfs) $(B)/conf/certs.conf
	@rm -f $(D)/nginx-configuration.tar
	@rm -fr $(T)/*

.PHONY: clean-tmp
clean-tmp:
	@rm -fr $(T)/*

$(D)/nginx-configuration.tar: $(B)/conf/certs.conf $(buildConfs)
	@#  nginx proxy configuration needs to see:
	@# 1. proxied connection so xqerl must be running
	@# 2. obtained certs are in certs location
	@echo ' - check nginx configuration'
	@$(dkrNginxMountAll) --network $(NETWORK) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c "./sbin/nginx -t"
	@echo ' - copy build files into "nginx-confguration" volume'
	@$(dkrCpNginxConf) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -r /tmp/conf ./ '
	@echo ' - tar the "nginx-confguration" volume into deploy directory'
	@$(dkrTarNginxConf) --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(PROXY_HOME)/conf > $@

$(B)/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@echo "$${mkCertsConf}" > $@

.PHONY: confs
confs: $(buildConfs)

$(B)/conf/%: conf/%
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	$(if $(LOCAL_RELOAD),echo ' - local reload: $(LOCAL_RELOAD)',)
	@$(if $(LOCAL_RELOAD),$(dkrCpNginxConf) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp  /tmp/conf/$(*) ./conf/',)
	@$(if $(LOCAL_RELOAD),$(DEN) ./sbin/nginx -t,)
	@$(if $(LOCAL_RELOAD),$(DEN) ./sbin/nginx -s reload,)
	@cp $< $@

.PHONY: watch-confs
watch-confs:
	@while true; do \
        $(MAKE) --silent confs LOCAL_RELOAD=yep ; \
        inotifywait -qre close_write . ; \
    done

#################################################
### PROXY UP DOWN RESTART and TEST CONFIG ###
#################################################
proxyRunning = $(shell docker ps --all --filter name=$(NGX) --format '{{.Status}}' | grep -oP '^Up' || true)

# docker inspect -f '{{.State.Running}}' $(NGX) | grep -oP '^true' || true
# orExited  != docker ps --all --filter name=$(NGX) --format '{{.Status}}' | grep -oP '^Exited' || true

define proxyRun
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

define proxyNoVolRun
docker run --rm \
 --hostname nginx \
 --network $(NETWORK) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c "./sbin/nginx -t" | tee $(@)
endef

.PHONY: check-init
check-init: clean-tmp $(T)/network.check $(T)/certs.check
	@$(proxyNoVolRun)

.PHONY: up
up: clean-tmp  $(T)/network.check $(T)/certs.check $(T)/config.check $(T)/xqerl-up.check
	@$(if $(proxyRunning),,$(proxyRun))
	@#$(if $(proxyRunning),docker ps --all --filter name=$(NGX) --format ' -  $(NGX) container status [ {{.Status}} ]',)

$(T)/xqerl-up.check:
	@docker ps --all --filter name=$(XQ) --format '{{.Status}}' &> $@
	@if grep -oP '^Up(.+)$$' $@ &>/dev/null ;then\
		$(call Tick, - xqerl: [ $$(tail -1 $@) ]); else \
		$(call Cross,- xqerl: [ down ]) && false; fi

ddd:
	@# if xqerl not up $@ will be removed
	@#docker ps --all --filter name=$(XQ) --format '{{.Status}}' &> $@
	@# grep -oP '^Up' $@ || $(call Cross, - xqerl down) && false
	@#$(call Tick,$@, - xqerl [ $(shell tail -1 $@) ])

$(T)/config.check:
	@# if config check fails $@ will be removed
	@$(dkrNginxMountAll) --network $(NETWORK) --entrypoint 'sh' $(PROXY_DOCKER_IMAGE) -c './sbin/nginx -t' &> $@
	@if grep -oP '^nginx:(.+)ok$$' $@ &>/dev/null ;then\
 $(call Tick, - $$(tail -1 $@)); else \
 $(call Cross, - $$(tail -1 $@)) && false; fi

$(T)/certs.check: $(T)/volumes.check
	@#echo '##[ $(notdir $@) ]##'
	@# inspect mounted volume for certs
	@docker run --rm \
 --mount $(mountLetsencrypt) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c \
 'ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)' > $@
	@# checks will remove certs.check if failure
	@grep -q 'privkey' $@
	@grep -q 'fullchain' $@
	@grep -q 'chain.pem' $@
	@grep -q 'cert' $@
	@$(call Tick, - certs OK!)

MustHaveVolume = docker volume list --format "{{.Name}}" | \
 grep -q $(1) || docker volume create --driver local --name $(1) &>/dev/null

$(T)/volumes.check:
	@# echo '##[ $(notdir $@) ]##'
	@docker volume list  --format "{{.Name}}" > $@
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,letsencrypt)
	@$(call Tick, - volumes OK!)

$(T)/network.check:
	@# echo '##[ $(notdir $@) ]##'
	@docker network list --format '{{.Name}}' > $@
	@grep -oP '^$(NETWORK)' $@ &>/dev/null || docker network create $(NETWORK)
	@$(call Tick, - network: [ $(NETWORK) ])

$(T)/port.check:
	@echo '##[ $@ ]##'
	@echo -n ' - check TLS port '
	@docker ps --format '{{.Ports}}' | tee $@
	@grep -oP '^(.+)443->\K(443)' $@ || echo  '[ 443 ] OK! can use.'
	@grep -oP '^(.+)443->\K(443)' $@ && echo  '[ 443 ] already in use '

.PHONY: down
down:
	@echo '##[ $@ ]##'
	@$(if $(proxyRunning),echo -n ' - stopping container: ' && docker stop $(NGX),)

.PHONY: reload
reload:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec  ./sbin/nginx -t
	@echo ' - local restart'
	@docker exec or ./sbin/nginx -s reload

.PHONY: info
info: $(T)/log-status
	@cat $<

$(T)/log-status:
	@echo "## $@ ##"
	@docker ps --filter name=$(NGX) --format '  name: {{.Names}}' > $@
	@docker ps --filter name=$(NGX) --format  'status: {{.Status}}'  >> $@
	@docker ps --filter name=$(NGX) --format '  ports:  {{.Ports}}' >> $@
	@docker inspect --format='IP addr: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(NGX) >> $@

$(T)/version-info:
	@docker exec -t or nginx -v
	@echo 'nginx modules'
	@grep -oP '^..add.module.+$$' $<
	@echo 'nginx compiled with'
	@grep -oP '^..with-[\w+-_]+$$' $<

#########################
### LETSENCRYPT CERTS ###
#########################
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(NGX) --command
mountCerts := type=bind,target=/tmp,source=$(CURDIR)/certs
mountGCE   := type=bind,target=/tmp,source=/home/$(GCE_NAME)/certs

LEpath  := $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
CopyCerts = docker cp or:$(LEpath)/$(1).pem ./certs -L

.PHONY: certs-into-vol
certs-into-vol: certs-to-host
	@docker run --rm \
 --mount $(mountLetsencrypt) \
 --mount  $(mountCerts) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c \
 'mkdir -p $(LEpath) \
 && mv /tmp/dh-param.pem $(LETSENCRYPT)/ \
 && cp /tmp/* $(LEpath)/ '

.PHONY: certs-to-host
certs-to-host:
	@# or just cat use the following certs
	@#$(Gcmd) 'rm -rf certs'
	@$(Gcmd) 'mkdir -p certs \
 && $(call CopyCerts,cert)  \
 && $(call CopyCerts,fullchain)  \
 && $(call CopyCerts,chain)  \
 && $(call CopyCerts,privkey)  \
 && docker cp or:$(LETSENCRYPT)/dh-param.pem ./certs -L \
 && ls -al ./certs'
	@gcloud compute scp $(GCE_NAME):~/certs ./ --recurse
	@printf %60s | tr ' ' '-' && echo

.PHONY: certs-check
certs-check:
	@$(GCmd) 'ls -al $(LEpath)'
	@docker run --rm \
 --mount $(mountLetsencrypt) \
 --entrypoint "ls" $(PROXY_DOCKER_IMAGE) -alR  $(LETSENCRYPT)
