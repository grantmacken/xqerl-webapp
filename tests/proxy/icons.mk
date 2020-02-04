

#clean static-assets

.PHONY: static-assets
static-assets: styles icons  

.PHONY: site-routes
site-routes:  home-page



# STYLES

.PHONY: styles
styles: styles-gzip styles-gunzip
	@echo '## $@ ##'

sdsdsff:
	@echo -n " - gzip-static size [ $(shell grep -oP '^gzip-size: \K(.+)' $(T)/styles/gzip.txt ) ]\
 should be smaller than gunzip size [ $(shell grep -oP '^gunzip-size: \K(.+)' $(T)/styles/gunzip.txt ) ] "
	@[[ $(shell grep -oP '^gzip-size: \K(.+)' $(T)/styles/gzip.txt ) -lt \
 $(shell grep -oP '^gunzip-size: \K(.+)' $(T)/styles/gunzip.txt ) ]] && $(OK)


.PHONY: styles-gzip
styles-gzip: $(T)/styles/gzip
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200, should serve header )
	@echo -n " - with gzip-static on then should serve header 'content-type: text/css'"
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),content-type: text/css)
	@echo " - with gzip-static on then should serve header 'content-type: text/css'"
	@#echo -n " - with gzip-static on then should serve header 'content-encoding: gzip'"
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),content-encoding: gzip)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@# etag for caching should serve *etag* header
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),etag)
	@#echo -n " - should serve *last-modified* header: "
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),last-modified)
	@#echo -n " - should serve *expires* header: "
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),expires)
	@#echo -n  " - should serve *cache-control* with long max age: "
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),cache-control)
	@#grep -q 'cache-control: max-age' $< && $(OK!) && grep -oP '^cache-control:.+$$' $<
	@#echo -n " - INFO: gzip-static size: "
	@#grep -oP '^gzip-size: \K(.+)$$' $<

.PHONY: styles-gunzip
styles-gunzip: $(T)/styles/gunzip
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),content-type: text/css)
	@#echo -n " - gunzip should NOT serve header 'content-encoding: gzip'"
	@#grep -q 'content-encoding: gzip' $< || $(OK)
	@#echo -n " - INFO: gunzip size: "
	@#grep -oP '^gunzip-size: \K(.+)$$' $<

$(T)/styles/gzip:
	@mkdir -p $(dir $@)
	@#curl -sI -H 'Accept-Encoding: gzip'  $(URL)/styles > $@
	@# curl -s --write-out 'gzip-size: %{size_download}' -H 'Accept-Encoding: gzip,deflate' --output /dev/null  $(URL)/styles >> $@
	@curl --silent --show-error \
 --resolve $(DOMAIN):443:$(orAddress) \
 -H 'Host: $(DOMAIN)' \
 -H 'Accept-Encoding: gzip' \
 --write-out $(WriteOut) \
 --dump-header $(dir $@)/headers-$(notdir $@) \
 --output /dev/null \
 $(URL)/styles > $@ 


$(T)/styles/gunzip:
	@mkdir -p $(dir $@)
	@curl --silent --show-error \
 --resolve $(DOMAIN):443:$(orAddress) \
 -H 'Host: $(DOMAIN)' \
 --write-out $(WriteOut) \
 --dump-header $(dir $@)/headers-$(notdir $@) \
 --output /dev/null \
 $(URL)/styles > $@ 

# ICONS

.PHONY: icons
icons: $(T)/icons/mail
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),content-type: image/svg+xml)
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),content-encoding: gzip)
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),vary: Accept-Encoding)

$(T)/icons/mail:
	@mkdir -p $(dir $@)
	@curl --silent --show-error \
 --resolve $(DOMAIN):443:$(orAddress) \
 -H 'Host: $(DOMAIN)' \
 --write-out $(WriteOut) \
 --dump-header $(dir $@)/headers-$(notdir $@) \
 --output /dev/null \
 $(URL)/icons/mail > $@ 

.PHONY: nginx-conf
nginx-conf: $(T)/nginx/conf/info
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)
	@# TODO


