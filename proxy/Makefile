SHELL=/bin/bash
include $(abspath ../.env)
XQ=$(XQERL_CONTAINER_NAME)
OR=$(PROXY_CONTAINER_NAME)
ifdef INC
 include .inc/$(INC).mk
 $(info included $(INC).mk )
endif

T := .tmp
B := .build
COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DELIMIT := $(COMMA)$(EMPTY)
DEO  = docker exec $(OR)

define ProxyHelp
-------------------------------------------------------------------------------
$(CURDIR)

PROXY_CONTAINER_NAME: $(PROXY_CONTAINER_NAME)
ENV OPENRESTY_HOME $(OPENRESTY_HOME)
ENV XQERL_CONTAINER_NAME $(XQERL_CONTAINER_NAME)
ENV XQERL_PORT $(XQERL_PORT)
 
-------------------------------------------------------------------------------
endef

help: export mkProxyHelp=$(ProxyHelp)
help:
	@echo "$${mkProxyHelp}"

.PHONY: conf
conf: clean \
 $(B)/nginx/conf/certs.conf $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))
	@echo '## $(@) ##'
	@$(DEO) ./bin/openresty -s reload

.PHONY: clean
clean:
	@echo '## $(@) ##'
	@rm -rf $(B)

define mkCertsConf
# My LETSENCRYPT certs
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
endef

define mkDockerfile
FROM  $(PROXY_IMAGE_FROM) as proxy
RUN  rm $(OPENRESTY_HOME)/nginx/conf/*
COPY ./nginx/conf  $(OPENRESTY_HOME)/nginx/conf
# add env vars
ENV PROXY_CONTAINER_NAME $(PROXY_CONTAINER_NAME)
ENV XQERL_CONTAINER_NAME $(XQERL_CONTAINER_NAME)
ENV XQERL_PORT $(XQERL_PORT)
endef

$(B)/proxy/conf/%.conf: proxy/conf/%.conf
	@echo '##[ $< ]##'
	@mkdir -p $(dir $@)
	@$(DEO) ls -al $(patsubst proxy/conf/%,nginx/conf/%,$<)
	@$(DEO) cat $(patsubst proxy/conf/%,nginx/conf/%,$<)
	@cp $< $@

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkCertsConf}" > $@
	@docker cp $@ $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@)
	@$(DEO) ls -al $(patsubst $(B)/%,%,$@)
	@$(DEO) ls -al ./bin
	@$(DEO) ./bin/openresty -c $(OPENRESTY_HOME)/nginx/conf/nginx.conf -t

$(B)/nginx/conf/%: conf/%
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@docker cp $< $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@)
	@$(DEO) ls -al $(patsubst $(B)/%,%,$@)
	@$(DEO) ./bin/openresty -c $(OPENRESTY_HOME)/nginx/conf/nginx.conf -t
	@cp $< $@

.PHONY: dkrLogin
dkrLogin:
	@echo '## $(@) ##'
	@$(if $${GITHUB_WORKSPACE},\
 echo ${{ secrets.GITHUB_TOKEN }} | docker login docker.pkg.github.com --username ${{ secrets.DOCKER_USERNAME }} --password-stdin,\
 echo ${GITHUB_ACCESS_TOKEN} | docker login docker.pkg.github.com --username $(REPO_OWNER) --password-stdin )

.PHONY: or-restart
or-restart:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec -t or openresty -t | grep 'syntax is ok'
	@echo ' - local restart'
	@#docker exec or kill -HUP 1
	@docker exec or openresty -s reload
	@#docker exec or openresty start
	@docker ps | grep 'openresty'

.PHONY: or-test
or-test:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec -t or openresty -t


.PHONY: orDummy
orDummy:
	@docker run --rm --name dummy --detach \
 --mount type=volume,target=${LETSENCRYPT},source=letsencrypt \
 --entrypoint "/usr/bin/tail" $(PROXY_DOCKER_IMAGE)  -f /dev/null




.PHONY: certsToHost
certsToHost:
	@echo '## $@ ##'
	@gcloud compute ssh $(GCE_NAME) --command 'mkdir -p ./live/$(TLS_COMMON_NAME)'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/cert.pem ./live/$(TLS_COMMON_NAME) -L'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem ./live/$(TLS_COMMON_NAME) -L'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem ./live/$(TLS_COMMON_NAME) -L'
	# dh param in different location
	@gcloud compute ssh $(GCE_NAME) --command  'docker cp or:$(LETSENCRYPT)/dh-param.pem ./live/$(TLS_COMMON_NAME) -L'
	@gcloud compute ssh $(GCE_NAME) --command 'ls -al ./live/$(TLS_COMMON_NAME)'
	@sudo mkdir -p $(LETSENCRYPT)
	@sudo chown ${USER} $(LETSENCRYPT)
	@gcloud compute scp  $(GCE_NAME):~/live $(LETSENCRYPT) --recurse
	# clean up on GCE Host
	@gcloud compute ssh $(GCE_NAME) --command 'rm -r ./live'
	# relocate dh param
	@mv $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/dh-param.pem $(LETSENCRYPT)/dh-param.pem
	@ls -al $(LETSENCRYPT)
	@ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	# create letsencrypt volume
	docker volume create --driver local --name letsencrypt
	# create a dummy container and attach to letsencypt volume
	@docker run --rm --name dummy --detach \
 --mount type=volume,target=${LETSENCRYPT},source=letsencrypt \
 --entrypoint "/usr/bin/tail" $(PROXY_DOCKER_IMAGE)  -f /dev/null
	# copy retrieved certs into letsencrypt volume
	docker cp $(LETSENCRYPT)/live/$(TLS_COMMON_NAME) dummy:$(LETSENCRYPT)/live 
	docker cp $(LETSENCRYPT)/dh-param.pem dummy:$(LETSENCRYPT)
	docker exec dummy ls $(LETSENCRYPT) 
	docker exec dummy ls $(LETSENCRYPT)/live
	docker stop dummy
	# on github host we should be able to copy into a stopped container
	# adjust hosts file TODO all domains
	@echo "127.0.0.1  $(TLS_COMMON_NAME)" | sudo tee -a /etc/hosts
	@printf %60s | tr ' ' '-' && echo


