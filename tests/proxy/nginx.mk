
.PHONY: nginx-conf
nginx-conf: $(T)/nginx/conf/info
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)
	@# TODO

$(T)/nginx/conf/info:
	@mkdir -p $(dir $@)
	@$(call GET,/_info,$@)
