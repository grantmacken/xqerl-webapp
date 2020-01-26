SHELL=/bin/bash
include ../../../.env
XQ := $(XQERL_CONTAINER_NAME)
OR := $(PROXY_CONTAINER_NAME)

DOMAIN = gmack.nz
T = .tmp

IPAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
dkrStatus != docker ps --filter name=$(XQ) --format 'status: {{.Status}}'
dkrPortInUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+)80->\K(80)'
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"
URL := https://$(DOMAIN)

define OK
tput setaf 2
echo -n ' ✓ ' 
tput sgr0
echo
endef

define OK!
tput setaf 2
echo -n ' ✓ # ' 
tput sgr0
endef

.PHONY: test
test: clean static-assets nginx-conf

.PHONY: static-assets
static-assets: styles icons  

.PHONY: site-routes
site-routes:  home-page



.PHONY: clean
clean:
	@rm -rf $(T)

# STYLES

.PHONY: styles
styles: styles-gzip styles-gunzip
	@echo '## $@ ##'
	@echo -n " - gzip-static size [ $(shell grep -oP '^gzip-size: \K(.+)' $(T)/styles/gzip.txt ) ]\
 should be smaller than gunzip size [ $(shell grep -oP '^gunzip-size: \K(.+)' $(T)/styles/gunzip.txt ) ] "
	@[[ $(shell grep -oP '^gzip-size: \K(.+)' $(T)/styles/gzip.txt ) -lt \
 $(shell grep -oP '^gunzip-size: \K(.+)' $(T)/styles/gunzip.txt ) ]] && $(OK)


.PHONY: styles-gzip
styles-gzip: $(T)/styles/gzip.txt
	@echo '## $@ ##'
	@echo -n ' - should serve HTTP/2'
	@grep -q 'HTTP/2 200' $< && $(OK)
	@echo -n " - with gzip-static on then should serve header 'content-type: text/css'"
	@grep -q 'content-type: text/css' $< && $(OK)
	@echo -n " - with gzip-static on then should serve header 'content-encoding: gzip'"
	@grep -q 'content-encoding: gzip' $< && $(OK)
	@echo -n ' - should serve *etag* header: '
	@grep -q 'etag:'  $< && $(OK!) && grep -oP '^etag:.+$$' $<
	@echo -n " - should serve *last-modified* header: "
	@grep -q 'last-modified:' $<  && $(OK!) && grep -oP '^last-modified:.+$$' $<
	@echo -n " - should serve *expires* header: "
	@grep -q 'expires:' $<  && $(OK!)  && grep -oP '^expires:.+$$' $<
	@echo -n  " - should serve *cache-control* with long max age: "
	@grep -q 'cache-control: max-age' $< && $(OK!) && grep -oP '^cache-control:.+$$' $<
	@echo -n " - INFO: gzip-static size: "
	@grep -oP '^gzip-size: \K(.+)$$' $<

.PHONY: styles-gunzip
styles-gunzip: $(T)/styles/gunzip.txt
	@echo '## $@ ##'
	@echo -n " - gunzip should serve header 'content-type: text/css'"
	@grep -q 'content-type: text/css' $< && $(OK)
	@echo -n " - gunzip should NOT serve header 'content-encoding: gzip'"
	@grep -q 'content-encoding: gzip' $< || $(OK)
	@echo -n " - INFO: gunzip size: "
	@grep -oP '^gunzip-size: \K(.+)$$' $<


$(T)/styles/gzip.txt:
	@mkdir -p $(dir $@)
	@curl -sI -H 'Accept-Encoding: gzip'  $(URL)/styles > $@
	@curl -s --write-out 'gzip-size: %{size_download}' -H 'Accept-Encoding: gzip,deflate' --output /dev/null  $(URL)/styles >> $@

$(T)/styles/gunzip.txt:
	@mkdir -p $(dir $@)
	@curl -sI $(URL)/styles > $@
	@curl -s --write-out 'gunzip-size: %{size_download}' --output /dev/null  $(URL)/styles >> $@

# ICONS

.PHONY: icons
icons: $(T)/icons/mail.txt
	@echo '## $@ ##'
	@echo -n ' - should serve HTTP/2'
	@grep -q 'HTTP/2 200' $< && $(OK)
	@echo -n " - should serve header [ content-type: image/svg+xml ]"
	@grep -q 'content-type: image/svg+xml'  $< && $(OK)
	@echo -n " - should serve header [ content-encoding: gzip ]"
	@grep -q 'content-encoding: gzip'  $< && $(OK) || false
	@echo -n " - should serve header [ vary: Accept-Encoding ]"
	@grep -q 'vary: Accept-Encoding'  $< && $(OK) || false

$(T)/icons/mail.txt:
	@mkdir -p $(dir $@)
	@curl -sI $(URL)/icons/mail > $@


# proxy nginx configuration

.PHONY: nginx-conf
nginx-conf: $(T)/nginx/conf/info
	@echo '## $@ ##'
	@# TODO
	@cat $< 
	@echo
	@cat $(dir $@)/doc-$(notdir $@)
	@echo
	@cat  $(dir $@)/headers-$(notdir $@)
	@echo

$(T)/nginx/conf/info:
	@mkdir -p $(dir $@)
	@curl -s \
 --output $(dir $@)/doc-$(notdir $@)\
 --write-out "response-code: %{http_code}\\ntotal-time: %{time_total}\\ntime_connect: %{time_connect}" \
 --dump-header $(dir $@)/headers-$(notdir $@) \
 $(URL) | tee $@ 


# RESTXQ ROUTES

.PHONY: home-page
home-page: $(T)/site/home-page
	@echo '## $@ ##'
	@echo -n ' - response code should be 200'
	@grep -q 'response-code: 200' $< && $(OK)
	@# TODO
	@#cat $<
	@#cat $(dir $<)/doc-$(notdir $<)
	@#cat $(dir $<)/headers-$(notdir $<)

#TODO add more
# https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout

$(T)/site/home-page:
	@mkdir -p $(dir $@)
	@curl -s \
 --output $(dir $@)/doc-$(notdir $@)\
 --write-out "response-code: %{http_code}\\ntotal-time: %{time_total}\\ntime_connect: %{time_connect}" \
 --dump-header $(dir $@)/headers-$(notdir $@) \
 $(URL) | tee $@ 
	@echo



