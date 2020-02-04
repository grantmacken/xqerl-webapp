.PHONY: routes
routes: home-page

.PHONY: home-page
home-page: $(T)/routes/home-page
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200,should server http 2 )
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)

$(T)/routes/home-page:
	@mkdir -p $(dir $@)
	@$(call GET,/,$@)
