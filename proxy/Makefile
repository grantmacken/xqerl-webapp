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
D :=  ../deploy

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

.PHONY: conf
conf: $(D)/nginx-configuration.tar
	@#$(DEO) bin/openresty -t
	@#$(DEO) bin/openresty -s reload

.PHONY: clean
clean:
	@echo '## $(@) ##'
	@rm -f $(buildConfs)
	@rm -f $(D)/nginx-configuration.tar

$(D)/nginx-configuration.tar: build
	@mkdir -p $(dir $@)
	@echo ' - tar the "nginx-confguration" volume into deploy directory' 
	@$(dkrTarRun) --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - $(OPENRESTY_HOME)/nginx/conf > $@

.PHONY: build
build: $(B)/nginx/conf/certs.conf confs
	@echo ' - build complete ... '
	@echo ' - copy build files into "nginx-confguration" volume'
	@$(dkrCpRun) --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -r /tmp/nginx ./ '

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkCertsConf}" > $@

.PHONY: confs
confs: $(buildConfs)

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

include .inc/up.mk .inc/certs.mk 

