
### REPO OWNERS LUALIBS
##############################
# TODO mount at site/lualib not site/lualib/$(REPO_OWNER)

RelPathLibs := site/lualib/$(REPO_OWNER)
MountLibs :=  type=volume,target=$(OPENRESTY_HOME)/$(RelPathLibs),source=repo-owners-lualibs

.PHONY: libs  
libs: $(patsubst lualib/%.lua,$(B)/$(RelPathLibs)/%.lua, $(wildcard lualib/*))
	@echo '## $(@) $(CURDIR)  ##'
	@docker run --rm \
 --mount $(MountLibs) \
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

PHONY: clean-libs
clean-libs:
	@echo '## $(@) ##'
	@rm -rf $(B)/site
	@#$(DEO) rm -fr site/lualib/$(REPO_OWNER)
	@$(DEO) mkdir -p site/lualib/$(REPO_OWNER)



