
# ICONS

.PHONY: icons
icons: $(T)/icons/mail
	@echo '## $@ ##'
	@$(call ServesHeader,$(call fHeader,mail,$<),HTTP/2 200,should server http 2 )
	@$(call HasHeaderKeyShowValue,$(call fHeader,mail,$<),strict-transport-security)
	@$(call ServesContentType,$(call fHeader,mail,$<),content-type,image/svg+xml)
	@$(call ServesContentType,$(call fHeader,mail,$<),content-encoding,gzip)
	@$(call ServesContentType,$(call fHeader,mail,$<),vary,Accept-Encoding)


.PHONY: clean-icons
clean-icons:
	@rm -f $(T)/icons/*

$(T)/icons/mail:
	@mkdir -p $(dir $@)
	@$(call binGET,/icons/mail,$@)
