SHELL=/bin/bash
include .env
include ../.env
T := .tmp
B := .build
COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DELIMIT := $(COMMA)$(EMPTY)

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

