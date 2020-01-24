
# NOTE: repo owner directory is already created on container

$(B)/site/lualib/$(REPO_OWNER)/%.lua: lualib/%.lua
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@# docker cp $< $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@)
	@cp $<  $@
