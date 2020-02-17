
######################################
gzipSize  =  $(shell grep -oP '^ download\s+\[\s\K(\d+)' $(T)/styles/gzip || true )
gunzipSize = $(shell grep -oP '^ download\s+\[\s\K(\d+)' $(T)/styles/gunzip || true )
#gzipTransfer != grep -oP '^ tansfered\s+\[\s\K([.\d]+)' $(T)/styles/gzip
#gunzipTransfer != grep -oP '^ tansfered\s+\[\s\K([.\d]+)' $(T)/styles/gunzip
# $(call IsLessThan,$(gzipTransfer),$(gunzipTransfer),xx)
# echo '$(gzipTransfer) >= $(gunzipTransfer)' | bc

.PHONY: styles
styles: styles-gzip styles-gunzip
	@echo '## $@ ##'
	@echo " - with gziped files we should get a size reduction"
	@$(call IsLessThan,$(gzipSize),$(gunzipSize),gzip size should be smaller than gunzip )

.PHONY: clean-styles
clean-styles:
	@rm -f $(T)/styles/*

.PHONY: styles-gzip
styles-gzip: $(T)/styles/gzip
	@echo '## $@ ##'
	@echo " - with gzip-static on then we should serve header 'content-encoding: gzip'"
	@echo " - with gzip-static on then we should serve header 'content-type: text/css'"
	@echo " - with gzip-static on then we should serve header 'vary: Accept-Encoding'"
	@echo " - for caching we should serve *etag* header"
	@echo " - for caching we should serve *last-modified* header"
	@echo " - for caching we should serve serve *cache-control* with long max age"
	@echo " - for caching we should serve serve *expires* header"
	@$(call ServesHeader,$(call fHeader,gzip,$<),HTTP/2 200,should server http 2 )
	@$(call ServesContentType,$(call fHeader,gzip,$<),content-encoding,gzip)
	@$(call ServesContentType,$(call fHeader,gzip,$<),content-type,text/css)
	@$(call ServesContentType,$(call fHeader,gzip,$<),vary,Accept-Encoding)
	@$(call HasHeaderKeyShowValue,$(call fHeader,gzip,$<),last-modified)
	@$(call HasHeaderKeyShowValue,$(call fHeader,gzip,$<),etag)
	@$(call HasHeaderKeyShowValue,$(call fHeader,gzip,$<),expires)
	@$(call HasHeaderKeyShowValue,$(call fHeader,gzip,$<),cache-control)
	@$(call HasHeaderKeyShowValue,$(call fHeader,gzip,$<),strict-transport-security)

$(T)/styles/gzip:
	@mkdir -p $(dir $@)
	@curl --silent --show-error \
 --resolve $(DOMAIN):443:$(orAddress) \
 -H 'Host: $(DOMAIN)' \
 -H 'Accept-Encoding: gzip' \
 --write-out $(WriteOut) \
 --dump-header $(dir $@)/headers-$(notdir $@) \
 --output /dev/null \
 $(URL)/styles > $@

.PHONY: styles-gunzip
styles-gunzip: $(T)/styles/gunzip
	@echo '## $@ ##'
	@echo " - gunzip should serve header 'content-type: text/css'"
	@echo " - gunzip should NOT serve header 'content-encoding: gzip'"
	@$(call ServesHeader,$(call fHeader,gunzip,$<),HTTP/2 200,should server http 2 )
	@$(call ServesContentType,$(call fHeader,gunzip,$<),content-type,text/css)
	@$(call NotServesHeader,$(call fHeader,gunzip,$<),content-encoding)

$(T)/styles/gunzip:
	@mkdir -p $(dir $@)
	@$(call binGET,/styles,$@)
