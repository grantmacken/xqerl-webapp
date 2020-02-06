
# ICONS

.PHONY: icons
icons: $(T)/icons/mail
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200,should server http 2 )
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call ServesContentType,$(call fHeader,mail,$<),content-type,image/svg+xml)
	@$(call ServesContentType,$(call fHeader,mail,$<),content-encoding,gzip)
	@$(call ServesContentType,$(call fHeader,mail,$<),vary,Accept-Encoding)

$(T)/icons/mail:
	@mkdir -p $(dir $@)
	@$(call binGET,/icons/mail,$@)

