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


.PHONY: test
test: clean styles

.PHONY: clean
clean:
	@rm -r $(T)

# STYLES

.PHONY: styles
styles: styles-gzip styles-gunzip
	@echo '## $@ ##'
	@echo -n " - gzip-static size [ $(shell grep -oP '^gzip-size: \K(.+)' $(T)/styles/gzip.txt ) ]\
 should be smaller than gunzip size [ $(shell grep -oP '^gunzip-size: \K(.+)' $(T)/styles/gunzip.txt ) ] "
	@[[ $(shell grep -oP '^gzip-size: \K(.+)' $(T)/styles/gzip.txt ) -lt \
 $(shell grep -oP '^gunzip-size: \K(.+)' $(T)/styles/gunzip.txt ) ]] && echo ' OK!'


.PHONY: styles-gzip
styles-gzip: $(T)/styles/gzip.txt
	@echo '## $@ ##'
	@echo -n ' - should serve HTTP/2'
	@grep -q 'HTTP/2 200' $< && echo ': OK'
	@echo -n " - with gzip-static on then should serve header 'content-type: text/css'"
	@grep -q 'content-type: text/css' $< && echo ': OK'
	@echo -n " - with gzip-static on then should serve header 'content-encoding: gzip'"
	@grep -q 'content-encoding: gzip' $< && echo ': OK'
	@echo -n ' - should serve *etag* header: '
	@grep -q 'etag:'  $< && echo -n 'OK! # ' && grep -oP '^etag:.+$$' $<
	@echo -n " - should serve *last-modified* header: "
	@grep -q 'last-modified:' $<  && echo -n 'OK! # ' && grep -oP '^last-modified:.+$$' $<
	@echo -n " - should serve *expires* header: "
	@grep -q 'expires:' $<  && echo -n 'OK! # ' && grep -oP '^expires:.+$$' $<
	@echo -n  " - should serve *cache-control* with long max age: "
	@grep -q 'cache-control: max-age' $< && echo -n 'OK! ' && grep -oP '^cache-control:.+$$' $<
	@echo -n " - INFO: gzip-static size: "
	@grep -oP '^gzip-size: \K(.+)$$' $<

.PHONY: styles-gunzip
styles-gunzip: $(T)/styles/gunzip.txt
	@echo '## $@ ##'
	@echo -n " - gunzip should serve header 'content-type: text/css'"
	@grep -q 'content-type: text/css' $< && echo ': OK'
	@echo -n " - gunzip should NOT serve header 'content-encoding: gzip'"
	@grep -q 'content-encoding: gzip' $< || echo ': OK'
	@echo -n " - INFO: gunzip size: "
	@grep -oP '^gunzip-size: \K(.+)$$' $<


$(T)/styles/gzip.txt:
	@echo '## $@ ##'
	@mkdir -p $(dir $@)
	@echo 'Fetch Main Stylesheet WITH: [ Header: Accept-Encoding: gzip ]'
	@curl -sI -H 'Accept-Encoding: gzip'  $(URL)/styles > $@
	@curl -s --write-out 'gzip-size: %{size_download}' -H 'Accept-Encoding: gzip,deflate' --output /dev/null  $(URL)/styles >> $@

$(T)/styles/gunzip.txt:
	@echo '## $@ ##'
	@mkdir -p $(dir $@)
	@echo 'Fetch Main Stylesheet WITHOUT: [ Header: Accept-Encoding: gzip ]'
	@curl -sI $(URL)/styles > $@
	@curl -s --write-out 'gunzip-size: %{size_download}' --output /dev/null  $(URL)/styles >> $@

# ICONS

.PHONY: icons
icons: $(T)/icons/mail.txt
	@echo '## $@ ##'
	@echo -n ' - should serve HTTP/2'
	@grep -q 'HTTP/2 200' $< && echo ': OK'
	@echo -n " - should serve header [ content-type: image/svg+xml ]"
	@grep -q 'content-type: image/svg+xml'  $< && $(OK)
	@echo -n " - should serve header [ content-encoding: gzip ]"
	@grep -q 'content-encoding: gzip'  $< && $(OK) || false
	@echo -n " - should serve header [ vary: Accept-Encoding ]"
	@grep -q 'vary: Accept-Encoding'  $< && $(OK) || false

$(T)/icons/mail.txt:
	@mkdir -p $(dir $@)
	@curl -sI $(URL)/icons/mail > $@

