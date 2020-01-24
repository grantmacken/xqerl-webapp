SHELL=/bin/bash
include $(abspath ../.env)

OR=$(PROXY_CONTAINER_NAME)

T := .tmp
B := .build
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
	@echo '## $(@) ##'
	@#$(DEO) ls -al site/lualib/$(REPO_OWNER)
	@docker run --rm --name dummy --detach \
 --mount type=volume,target=$(OPENRESTY_HOME)/site/lualib/$(REPO_OWNER),source=repo-owners-lualibs \
 --entrypoint "/usr/bin/tail" $(PROXY_DOCKER_IMAGE)  -f /dev/null
	@docker cp $(B)/site/lualib/$(REPO_OWNER)/. dummy:$(OPENRESTY_HOME)/site/lualib/$(REPO_OWNER)
	@docker stop dummy

clean-libs:
	@echo '## $(@) ##'
	@rm -rf $(B)/site
	@#$(DEO) rm -fr site/lualib/$(REPO_OWNER)
	@$(DEO) mkdir -p site/lualib/$(REPO_OWNER)

.PHONY: confs certs conf
confs: $(patsubst %,$(B)/nginx/%, $(wildcard conf/*))
certs: $(B)/nginx/conf/certs.conf
conf: certs confs
	@echo '## $(@) ##'
	@docker run --rm --name dummy --detach \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
 --entrypoint "/usr/bin/tail" $(PROXY_DOCKER_IMAGE)  -f /dev/null
	@docker cp $(B)/nginx/conf/. dummy:$(OPENRESTY_HOME)/nginx/conf
	@#docker exec dummy $(OPENRESTY_HOME/bin/openresty -c $(OPENRESTY_HOME)/nginx/conf/nginx.conf -t)
	@# docker exec dummy bin/openresty -c $(OPENRESTY_HOME)/nginx/conf/nginx.conf -t
	@docker exec dummy  ls -al nginx/conf
	@docker stop dummy

sdsfgg:
	@$(if $(GITHUB_ACTIONS),$(call dummyRun),)
	@docker run --rm --name dummy --detach \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/conf,source=nginx-configuration \
 --entrypoint "/usr/bin/tail" $(PROXY_DOCKER_IMAGE)  -f /dev/null
	@docker cp $(B)/resources dummy:$(OPENRESTY_HOME)/$(STATIC_ASSETS)
	@$(if $(GITHUB_ACTIONS),docker cp $(B)/resources dummy:$(OPENRESTY_HOME)/$(STATIC_ASSETS),)
	@$(if $(GITHUB_ACTIONS),,echo "- live cp";$(DEO) ./bin/openresty -c $(OPENRESTY_HOME)/nginx/conf/nginx.conf -t)
	@$(if $(GITHUB_ACTIONS),,$(DEO) ./bin/openresty -s reload)

.PHONY: clean-conf
clean-conf:
	@echo '## $(@) ##'
	@rm -rf $(B)/nginx


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
	@docker exec or openresty -t | grep 'syntax is ok'
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


