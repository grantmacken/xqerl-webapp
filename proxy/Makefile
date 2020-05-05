SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include ../.env
T := .tmp
B := .build
D := ../deploy
MY_BIN_PATH=$(abspath ../bin)
$(shell mkdir -p ./{$(T),$(B)/conf,$(D)})
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DOT := .

ifeq ($(origin GITHUB_ACTIONS),undefined)
 GITHUB_ACTIONS := $(EMPTY)
endif

DEN  = docker exec $(PROXY_CONTAINER_NAME)
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
MountNginxConf   := type=volume,target=$(PROXY_HOME)/conf,source=nginx-configuration
MountNginxHtml   := type=volume,target=$(PROXY_HOME)/html,source=static-assets
MountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
MountAssets      := type=volume,target=$(PROXY_HOME)/html,source=static-assets
# local mounts
MountBuild       := type=bind,target=/tmp,source=$(CURDIR)/$(B)
MountConf      := type=bind,target=/tmp,source=$(CURDIR)/conf
MountCerts       := type=bind,target=/tmp,source=$(CURDIR)/certs
MountHtml       := type=bind,target=/tmp,source=$(CURDIR)/html
MountGCE         := type=bind,target=/tmp,source=/home/$(GCE_NAME)/certs

dkrCpNginxConf   := docker run --rm --mount $(MountNginxConf) --mount $(MountBuild)
dkrNginxConf  := docker run --rm --mount $(MountNginxConf)
dkrNginxMountAll := docker run --rm --mount $(MountNginxConf) --mount $(MountNginxHtml) --mount $(MountLetsencrypt)

buildConfs := $(patsubst %,$(B)/%, $(wildcard conf/*))

orAddress  := docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(PROXY_CONTAINER_NAME)

.PHONY: build
build: $(D)/nginx-configuration.tar
	@$(if $(GITHUB_ACTIONS),,xdotool search --onlyvisible --name "Mozilla Firefox"  key  Control_L+F5 || true)

.PHONY: restore
restore:
	@$(dkrCpNginxConf) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp /tmp/conf/$(TARG) ./conf/ '

.PHONY: ls
ls:
	@$(dkrNginxConf) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'ls -al ./conf'

.PHONY: rm
rm: 
	@$(dkrNginxConf) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'rm ./conf/$(TARG)'

.PHONY: cat
cat: 
	@$(dkrNginxConf) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cat ./conf/$(TARG)'


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
	@$(dkrNginxConf) --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(PROXY_HOME)/conf > $@

$(B)/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@echo "$${mkCertsConf}" > $@

.PHONY: confs
confs: $(buildConfs)

$(B)/conf/%: $(T)/conf/%
	@echo '## $(*) ##'
	@cat $<

xxxsss:
	@if grep -oP 'test is successful' $< &>/dev/null ;then\
    $(call Tick,- nginx: [ config OK ]); else \
    $(call Cross,- nginx: [ config err ]); fi

define cmdTestConf
mv -v ./conf/$(*)  ./conf/hold_$(*)
cp -v /tmp/$(*) ./conf/
if ./sbin/nginx -t ; then
  rm -v ./conf/hold_$(*)
  true
else 
  mv -v  ./conf/hold_$(*) ./conf/$(*)
  false
fi
endef

$(B)/conf/%: conf/%
	@echo '## $(*) ##'
	@mkdir -p $(dir $@)
	$(if $(GITHUB_ACTIONS),,echo ' - test configuration')
	@$(if $(GITHUB_ACTIONS),,\
 $(dkrNginxMountAll) \
 --mount $(MountConf) \
 --network $(NETWORK) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) \
 -c '$(cmdTestConf)' \
 )
	$(if $(GITHUB_ACTIONS),,echo ' -  reload nginx')
	@$(if $(GITHUB_ACTIONS),,$(DEN) ./sbin/nginx -s reload)
	@cp $< $@

.PHONY: watch
watch:
	@while true; do \
        $(MAKE) --silent confs; \
        inotifywait -qre close_write . ; \
    done

#################################################
### PROXY UP DOWN RESTART and TEST CONFIG ###
#################################################
proxyRunning = $(shell docker ps --all --filter name=$(PROXY_CONTAINER_NAME) --format '{{.Status}}' | grep -oP '^Up' || true)

# docker inspect -f '{{.State.Running}}' $(PROXY_CONTAINER_NAME) | grep -oP '^true' || true
# orExited  != docker ps --all --filter name=$(PROXY_CONTAINER_NAME) --format '{{.Status}}' | grep -oP '^Exited' || true

define proxyRun
docker run --rm \
 --mount $(MountNginxConf) \
 --mount $(MountNginxHtml) \
 --mount $(MountLetsencrypt) \
 --name  $(PROXY_CONTAINER_NAME) \
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
	@#$(if $(proxyRunning),docker ps --all --filter name=$(PROXY_CONTAINER_NAME) --format ' -  $(PROXY_CONTAINER_NAME) container status [ {{.Status}} ]',)

$(T)/xqerl-up.check:
	@docker ps --all --filter name=$(XQERL_CONTAINER_NAME) --format '{{.Status}}' &> $@
	@if grep -oP '^Up(.+)$$' $@ &>/dev/null ;then\
		$(call Tick, - xqerl: [ $$(tail -1 $@) ]); else \
		$(call Cross,- xqerl: [ down ]) && false; fi

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
 --mount $(MountLetsencrypt) \
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
	@$(if $(proxyRunning),echo -n ' - stopping container: ' && docker stop $(PROXY_CONTAINER_NAME),)

.PHONY: reload
reload:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -t
	@echo ' - local restart'
	@docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -s reload

.PHONY: info
info: $(T)/log-status 	
	@#cat $(T)/log-status
	@echo "$$(docker exec -t $(PROXY_CONTAINER_NAME) ./sbin/nginx -V)" > $(T)/version-info
	@cat $(T)/version-info | grep -oP 'configure arguments: \K.+' | tr ' ' '\n' > $(T)/configure.arguments
	@# cat $(T)/configure.arguments
	@printf %60s | tr ' ' '-' && echo
	@echo 'nginx compiled with'
	@printf %60s | tr ' ' '-' && echo
	@grep -oP '^..with-\K[\w+-_]+$$' $(T)/configure.arguments
	@printf %60s | tr ' ' '-' && echo
	@echo 'nginx dynamic modules'
	@printf %60s | tr ' ' '-' && echo
	@grep -oP '^..add.dynamic.module.+modules/\K.+$$' $(T)/configure.arguments
	@printf %60s | tr ' ' '-' && echo
	@#/bin/grep 'configure' $(T)/version-info

$(T)/log-status:
	@echo "## $@ ##"
	@find $(T)/ -type f | xargs rm -f
	@docker ps --filter name=$(PROXY_CONTAINER_NAME) --format '  name: {{.Names}}' > $@
	@docker ps --filter name=$(PROXY_CONTAINER_NAME) --format  'status: {{.Status}}'  >> $@
	@docker ps --filter name=$(PROXY_CONTAINER_NAME) --format '  ports:  {{.Ports}}' >> $@
	@docker inspect --format='IP addr: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(PROXY_CONTAINER_NAME) >> $@

$(T)/version-info:
	@echo "$$(docker exec $(PROXY_CONTAINER_NAME) ./sbin/nginx -V)" > $@

#########################
### LETSENCRYPT CERTS ###
#########################
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(PROXY_CONTAINER_NAME) --command
LEpath  := $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
CopyCerts = docker cp $(PROXY_CONTAINER_NAME):$(LEpath)/$(1).pem ./certs -L

.PHONY: certs-into-vol
certs-into-vol: certs-to-host
	@docker run --rm \
 --mount $(MountLetsencrypt) \
 --mount  $(MountCerts) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c \
 'mkdir -p $(LEpath) \
 && mv /tmp/dh-param.pem $(LETSENCRYPT)/ \
 && cp /tmp/* $(LEpath)/ '

.PHONY: certs-to-host
certs-to-host:
	@# or just cat use the following certs
	@#$(Gcmd) 'rm -rf certs'
	@find ./certs/ -type f | xargs rm -f
	@$(Gcmd) 'mkdir -p certs \
 && $(call CopyCerts,cert)  \
 && $(call CopyCerts,fullchain)  \
 && $(call CopyCerts,chain)  \
 && $(call CopyCerts,privkey)  \
 && docker cp $(PROXY_CONTAINER_NAME):$(LETSENCRYPT)/dh-param.pem ./certs -L \
 && ls -al ./certs'
	@gcloud compute scp $(GCE_NAME):~/certs ./ --recurse
	@printf %60s | tr ' ' '-' && echo

.PHONY: certs-check
certs-check:
	@$(GCmd) 'ls -al $(LEpath)'
	@docker run --rm \
 --mount $(MountLetsencrypt) \
 --entrypoint "ls" $(PROXY_DOCKER_IMAGE) -alR  $(LETSENCRYPT)

dkrCpNginxHtml   := docker run --rm --mount $(MountAssets) --mount $(MountHtml)
dkrTarNginxHtml  := docker run --rm --mount $(MountAssets)

.PHONY: index-html
index-html:
	@echo '## $@ ##'
	@#$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'ls /tmp/'
	@#$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'ls ./html'
	@$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp /tmp/* ./html/'
	@$(dkrCpNginxHtml) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'ls ./html'
	@echo ' - tar the "nginx-confguration" volume into deploy directory'
	@$(dkrTarNginxHtml) --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(PROXY_HOME)/html > $@


