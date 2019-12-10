SHELL=/bin/bash
include .env
include ../.env
ifdef INC
 include .inc/$(INC).mk
 $(info included $(INC).mk )
endif

HOST := $(PROJECT_NAME)
T := .tmp
B := .build
COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DELIMIT := $(COMMA)$(EMPTY)

define mkHelp
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
endef

help: export HELP=$(mkHelp)
help:
	@echo "$${HELP}"


.PHONY: build
build: clean \
 $(B)/Dockerfile \
 $(B)/docker-compose.yml \
 $(B)/nginx/conf/certs.conf \
 $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))
	@echo '## $(@) ##'
	@cd $(B); docker build --tag='docker.pkg.github.com/$(REPO_OWNER)/$(REPO_NAME)/$(PROXY_NAME):$(PROXY_VER)' .
	@docker images


.PHONY: dkrLogin
dkrLogin:
	@echo '## $(@) ##'
	@$(if ${GITHUB_WORKSPACE},\
 echo ${{ secrets.GITHUB_TOKEN }} | docker login docker.pkg.github.com --username ${{ secrets.DOCKER_USERNAME }} --password-stdin,\
 echo ${GITHUB_ACCESS_TOKEN} | docker login docker.pkg.github.com --username $(REPO_OWNER) --password-stdin )

xxxx:
	@cd $(B) ; docker-compose up -d
	@sleep 1
	@cd $(B); docker-compose logs
	@curl -s http://localhost
	@cd $(B) ; docker-compose down

.PHONY: clean
clean:
	@echo '## $(@) ##'
	@rm -rf $(B)

define mkDockerfile
FROM  $(IMAGE_FROM) as proxy
RUN  rm nginx/conf/*
COPY ./nginx/conf  $(OPENRESTY_HOME)/nginx/conf
RUN  ls -al nginx/conf
endef

define mkCertsConf
# My LETSENCRYPT certs
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
#  Diffie-Hellman parameter for DHE ciphersuites
##################################################
ssl_dhparam /etc/letsencrypt/dh-param.pem;
endef

define mkDockerCompose
version: '3.7'
services:
  openresty:
    container_name: orProxy
    image: ${DOCKER_IMAGE}:proxy
    ports:
        - 80:80
        - 443:443
endef

$(B)/Dockerfile: export mkDockerfile:=$(mkDockerfile)
$(B)/Dockerfile:
	@echo '## $(@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkDockerfile}" > $@

$(B)/docker-compose.yml: export mkDockerCompose:=$(mkDockerCompose)
$(B)/docker-compose.yml:
	@echo '## $(@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkDockerCompose}" > $@

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkCertsConf}" > $@

$(B)/nginx/conf/%: conf/%
	@echo '## $(@) ##'
	@mkdir -p $(dir $@)
	@cp $< $@

.PHONY: sa
sa: 
	@#gcloud iam service-accounts list
	@#gcloud iam service-accounts create gcp-service-account --description "My gmack service account" --display-name "gmackServiceAccount"
	@#gcloud iam service-accounts list
	@#gcloud iam service-accounts keys create ../../key.json --iam-account gcp-service-account@gmack-200121.iam.gserviceaccount.com
	@#mkdir .tmp; cat ../../key.json | base64 > .tmp/key.txt
	@#gcloud auth activate-service-account --project=gmack-200121 --key-file=../../key.json 
	@#gcloud iam service-accounts keys list --iam-account gcp-service-account@gmack-200121.iam.gserviceaccount.com
	@#gcloud auth activate-service-account --project=gmack-200121 --key-
	@gcloud iam service-accounts list
