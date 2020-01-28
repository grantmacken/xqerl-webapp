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

# dummyRun = docker run --rm --name dummy --detach \
#  --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
#  --entrypoint "/usr/bin/tail" $(PROXY_DOCKER_IMAGE)  -f /dev/null

.PHONY: libs  clean-libs

libs: $(patsubst lualib/%.lua,$(B)/site/lualib/$(REPO_OWNER)/%.lua, $(wildcard lualib/*))
	@echo '## $(@) $(CURDIR)  ##'
	@docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/site/lualib/$(REPO_OWNER),source=repo-owners-lualibs \
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

clean-libs:
	@echo '## $(@) ##'
	@rm -rf $(B)/site
	@#$(DEO) rm -fr site/lualib/$(REPO_OWNER)
	@$(DEO) mkdir -p site/lualib/$(REPO_OWNER)

.PHONY: confs
confs: $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))

.PHONY: certs 
certs: $(B)/nginx/conf/certs.conf

.PHONY: conf
conf: certs confs
	@echo '## $(@) ##'
	@docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
 --mount type=bind,target=/tmp,source=$(CURDIR)/$(B) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -rv /tmp/nginx ./ '
	@$(if $(GITHUB_ACTIONS),,$(DEO) ./bin/openresty -t )
	@$(if $(GITHUB_ACTIONS),,$(DEO) ./bin/openresty -s reload)

###################################
# deploy nginx-configuration-volume
###################################

.PHONY: nginx-configuration-volume
nginx-configuration-volume: $(D)/nginx-configuration.tar
	gcloud compute scp $< $(GCE_NAME):~/deploy
	@gcloud compute ssh $(GCE_NAME) --command  'ls -al ./deploy'

$(D)/nginx-configuration.tar:
	@mkdir -p $(dir $@)
	echo '## $@ ##'
	@docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) -czf - ./nginx/conf > $@

.PHONY: clean-conf
clean-conf:
	@echo '## $(@) ##'
	@rm -rf  $(B)/nginx/conf

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





