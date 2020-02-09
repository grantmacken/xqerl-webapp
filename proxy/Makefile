SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
LOCAL_RELOAD := 
include ../.env
OR := $(PROXY_CONTAINER_NAME)
T := .tmp
B := .build
D := ../deploy
$(shell mkdir -p ./{$(T),$(B)/nginx/conf,$(D)})

DEO  = docker exec $(OR)

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
mountNginxConf   := type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration
mountNginxHtml   := type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets
mountLetsencrypt := type=volume,target=$(LETSENCRYPT),source=letsencrypt
mountSiteLualib  := type=volume,target=$(OPENRESTY_HOME)/site/lualib,source=site-lualib
mountBuild       := type=bind,target=/tmp,source=$(CURDIR)/$(B)

dkrTarRun  := docker run --rm --mount $(mountNginxConf)
dkrCpRun   := docker run --rm --mount $(mountNginxConf) --mount $(mountBuild) 
buildConfs := $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))

orAddress  := docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(OR)

.PHONY: build
build: $(D)/nginx-configuration.tar
	@#$(DEO) bin/openresty -t
	@#$(DEO) bin/openresty -s reload

.PHONY: clean
clean: clean-tmp
	@echo '## $(@) ##'
	@rm -f $(buildConfs) $(B)/nginx/conf/certs.conf
	@rm -f $(D)/nginx-configuration.tar
	@rm -fr $(T)/*

.PHONY: clean-tmp
clean-tmp:
	@rm -fr $(T)/*

$(D)/nginx-configuration.tar: $(B)/nginx/conf/certs.conf confs
	@echo ' - copy build files into "nginx-confguration" volume'
	@$(dkrCpRun) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -r /tmp/nginx ./ '
	@echo ' - tar the "nginx-confguration" volume into deploy directory' 
	@$(dkrTarRun) --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(OPENRESTY_HOME)/nginx/conf > $@

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@echo "$${mkCertsConf}" > $@

.PHONY: confs
confs: $(buildConfs)

$(B)/nginx/conf/%: conf/%
	@echo '## $(patsubst $(B)/%,%,$@) ##'
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

#################################################
### OPENRESTY UP DOWN RESTART and TEST CONFIG ###
#################################################
orRunning != docker ps --all --filter name=$(OR) --format '{{.Status}}' | grep -oP '^Up' || true

# docker inspect -f '{{.State.Running}}' $(OR) | grep -oP '^true' || true
# orExited  != docker ps --all --filter name=$(OR) --format '{{.Status}}' | grep -oP '^Exited' || true

define orRun
docker run --rm \
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
 $(PROXY_DOCKER_IMAGE)
endef

.PHONY: up
up: clean-tmp $(T)/network.check $(T)/certs.check
	@$(if $(orRunning),,$(orRun))
	@$(if $(orRunning),docker ps --all --filter name=$(OR) --format ' -  $(OR) container status [ {{.Status}} ]',)

# $(T)/certs.check  $(T)/network.check $(T)/port.check

$(T)/certs.check: $(T)/volumes.check
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

MustHaveVolume = docker volume list --format "{{.Name}}" | \
 grep -q $(1) || docker volume create --driver local --name $(1) &>/dev/null

$(T)/volumes.check:
	@#echo '##[ $@ ]##'
	@docker volume list  --format "{{.Name}}" > $@
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,letsencrypt)
	@$(call MustHaveVolume,site-lualib)

$(T)/network.check:
	@#echo '##[ $@ ]##'
	@docker network list --format '{{.Name}}' > $@
	@grep -oP '^$(NETWORK)' $@ &>/dev/null || docker network create $(NETWORK)

$(T)/port.check:
	@echo '##[ $@ ]##'
	@echo -n ' - check TLS port '
	@docker ps --format '{{.Ports}}' | tee $@
	@grep -oP '^(.+)443->\K(443)' $@ || echo  '[ 443 ] OK! can use.'
	@grep -oP '^(.+)443->\K(443)' $@ && echo  '[ 443 ] already in use '

.PHONY: down
down: 
	@echo '##[ $@ ]##'
	@$(if $(orRunning),echo -n ' - stopping container: ' && docker stop $(OR),)

.PHONY: reload
reload:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec or ./bin/openresty -t
	@echo ' - local restart'
	@docker exec or ./bin/openresty -s reload

.PHONY: config-test
config-test:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec -t or openresty -t

.PHONY: info
info: $(T)/log-status
	@cat $<

$(T)/log-status:
	@echo "## $@ ##"
	@docker ps --filter name=$(OR) --format '  name: {{.Names}}' > $@
	@docker ps --filter name=$(OR) --format  'status: {{.Status}}'  >> $@
	@docker ps --filter name=$(OR) --format '  ports:  {{.Ports}}' >> $@
	@docker inspect --format='IP addr: {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(OR) >> $@

$(T)/version-info:
	@docker exec -t or openresty -v
	@echo 'nginx modules'
	@grep -oP '^..add.module.+$$' $< 
	@echo 'nginx compiled with'
	@grep -oP '^..with-[\w+-_]+$$' $< 

#########################
### LETSENCRYPT CERTS ###
#########################
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(OR) --command 
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

