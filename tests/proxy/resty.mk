
.PHONY: resty-info
resty-info: $(T)/nginx/conf/info
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200, ok )
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)
	@# TODO

$(T)/nginx/conf/info:
	@mkdir -p $(dir $@)
	@$(call GET,/_info,$@)

.PHONY: callback
callback: callback-state


.PHONY: callback-noargs
callback-noargs: $(T)/lualib/callback-noargs
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 406,request to callback should have query args)

$(T)/lualib/callback-noargs:
	@mkdir -p $(dir $@)
	@$(call GET,/_callback,$@)

.PHONY: callback-state
callback-state: $(T)/lualib/callback-state
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 406,request to callback should have query args)

$(T)/lualib/callback-state:
	@mkdir -p $(dir $@)
	@$(call GET,/_callback?state=xxx&code=yyyy,$@)
