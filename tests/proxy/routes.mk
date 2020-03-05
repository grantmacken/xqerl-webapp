.PHONY: routes
routes: home-page

.PHONY: clean-routes
clean-routes:
	@rm -f res/routes/*

.PHONY: home-page
home-page: res/routes/home-page
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200,should server http 2 )
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)

res/routes/home-page:
	@mkdir -p $(dir $@)
	@$(call GET,/,$@)
