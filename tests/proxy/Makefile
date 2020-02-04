SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
########################################
SHELL=/bin/bash
include ../../.env
T = response
XQ := $(XQERL_CONTAINER_NAME)
OR := $(PROXY_CONTAINER_NAME)
##################################################################
orAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(OR)

Tick  = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo -n $1
HasHeaderKey   = grep -q '^$2' $1 
HeaderKeyValue =  echo "$$( grep -oP '^$2: \K(.+)$$' $1 )"
ServesHeader   = if $(call HasHeaderKey,$1,$2); \
 then $(call Tick, '- serves header [ $2 ] ') && echo; \
 else $(call Cross,'- failed header [ $2 ] ') && false; fi
HasHeaderKeyShowValue = \
 if $(call HasHeaderKey,$1,$2);then $(call Tick, "- header $2: " );$(call HeaderKeyValue,$1,$2);\
 else $(call Cross, "- header $2: " );false;fi
##################################################################
WriteOut := '\
 response code [ %{http_code} ]\n\
 content type  [ %{content_type} ]\n\
 SSL verify    [ %{ssl_verify_result} ] should be zero \n\
 remote ip     [ %{remote_ip} ]\n\
 local ip      [ %{local_ip} ]\n\
 speed         [ %{speed_download} ] the average download speed\n\
 SIZE     bytes sent \n\
 header   [ %{size_header} ] \n\
 request  [ %{size_request} ] \n\
 download [ %{size_download} ] \n\
 TIMER       [ 0.000000 ] start until \n\
 namelookup  [ %{time_namelookup} ] DNS resolution  \n\
 connect     [ %{time_connect} ] TCP connect  \n\
 appconnect: [ %{time_appconnect} ] SSL handhake \n\
 pretransfer [ %{time_pretransfer} ] before transfer \n\
 transfer    [ %{time_starttransfer} ] transfer start \n\
 tansfered   [ %{time_total} ] total transfered ' 

URL := https://$(DOMAIN)

GET = curl --silent --show-error \
 --resolve $(DOMAIN):443:$(orAddress) \
 -H 'Host: $(DOMAIN)' \
 --write-out $(WriteOut) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)$1 > $2 

######################################

.PHONY: test
test: clean icons styles nginx-conf site-routes 

######################################


#clean static-assets

.PHONY: static-assets
static-assets: styles icons  

.PHONY: site-routes
site-routes:  home-page

.PHONY: clean
clean:
	@rm -rf $(T)/*

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
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@#echo -n " - with gzip-static on then should serve header 'content-type: text/css'"
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),content-type: text/css)
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
	@#echo -n " - should serve header [ content-type: image/svg+xml ]"
	@#grep -q 'content-type: image/svg+xml'  $< && $(OK)
	@#echo -n " - should serve header [ content-encoding: gzip ]"
	@#grep -q 'content-encoding: gzip'  $< && $(OK) || false
	@#echo -n " - should serve header [ vary: Accept-Encoding ]"
	@#grep -q 'vary: Accept-Encoding'  $< && $(OK) || false

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




# https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout
# connections [ %{num_connects} ] new connects made in the recent transfer \n\
# redirect    [ %{time_starttransfer} ] final start \n\
# [ %{num_redirects} ] \n\

$(T)/nginx/conf/info:
	@mkdir -p $(dir $@)
	@$(call GET,/_info,$@)

	@#openssl s_client -connect $(orAddress):443 -servername $(DOMAIN)

# RESTXQ ROUTES

.PHONY: home-page
home-page: $(T)/site/home-page
	@echo '## $@ ##'
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)
	@# TODO
	@#cat $<



$(T)/site/home-page:
	@mkdir -p $(dir $@)
	@$(call GET,/,$@)
	@#docker logs $(OR)
	@#docker logs $(XQ)

.PHONY: mpNote
mpNote:
	@echo;printf %60s | tr ' ' '-' && echo
	@curl -v $(mpURL) -d h=entry -d content="$(CONTENT)"
	@echo;printf %60s | tr ' ' '-' && echo


.PHONY: mpDelete
mpDelete:
	@echo;printf %60s | tr ' ' '-' && echo
	@curl -v  $(mpURL) -d action=delete -d  url="https://gmack.nz/5NX0vZ"
	@echo;printf %60s | tr ' ' '-' && echo

.PHONY: mpUndelete
mpUndelete:
	@echo;printf %60s | tr ' ' '-' && echo
	@curl -v $(mpURL) -d action=undelete -d  url="https://gmack.nz/5NX0vZ"
	@echo;printf %60s | tr ' ' '-' && echo

define jsUpdateReplace
{
  "action": "update",
  "url": "https://$(DOMAIN)/5NX0vZ",
  "replace": {
    "content": ["hello moon"]
  }
}
endef

mpUpdateReplace: export UpdateReplace=$(jsUpdateReplace)
mpUpdateReplace:
	@echo "$${UpdateReplace}" | curl -v $(mpJSON) --data-binary @-
	@false
	@echo "$${UpdateReplace}" | 
	@echo;printf %60s | tr ' ' '-' && echo

