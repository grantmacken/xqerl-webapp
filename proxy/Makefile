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
include $(abspath ../.inc/nginx-configuration.mk) $(abspath ../.inc/lualibs.mk)

.PHONY: libs  clean-libs

libs: $(patsubst lualib/%.lua,$(B)/site/lualib/$(REPO_OWNER)/%.lua, $(wildcard lualib/*))
	@$(DEO) ls -al site/lualib/$(REPO_OWNER)

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
	@$(DEO) ls -al nginx/conf
	@$(DEO) ./bin/openresty -c $(OPENRESTY_HOME)/nginx/conf/nginx.conf -t
	@$(DEO) ./bin/openresty -s reload

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


