SHELL=/bin/bash
include ../../../.env
XQ := $(XQERL_CONTAINER_NAME)
OR := $(PROXY_CONTAINER_NAME)

DOMAIN = gmack.nz
T = .tmp

xqAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
orAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(OR)
xqStatus != docker ps --filter name=$(XQ) --format 'status: {{.Status}}'
port80InUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+)80->\K(80)'
networkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"
URL := https://$(DOMAIN)
urlXQ   := http:8080//$(xqAddress)

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

GET = curl --silent --show-error \
 --resolve $(DOMAIN):443:$(orAddress) \
 -H 'Host: $(DOMAIN)' \
 --write-out $(WriteOut) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)$1 > $2 



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
test: clean nginx-conf site-routes

#clean static-assets

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
#
#tput setaf 2
# echo -n ' ✓ ' 
# tput sgr0
# echo
Tick = echo -n "$$(tput setaf 2) ✔ $$(tput sgr0) " && echo -n $1
Cross = echo -n "$$(tput setaf 1) ✘ $$(tput sgr0) " && echo $1

HasHeaderKey = grep -q '^$2' $1 
HeaderKeyValue =  echo "$$( grep -oP '^$2: \K(.+)$$' $1 )"
Status = if $(call HasHeaderKey,$1,$2) ; then $(call Tick, '- serves http2 with 200 status [ $2 ] ');echo;fi
HasHeaderKeyShowValue = \
 if $(call HasHeaderKey,$1,$2);then $(call Tick, "- header $2: " );$(call HeaderKeyValue,$1,$2);\
 else $(call Cross, "- header $2: " );false;fi


# ✗
.PHONY: nginx-con
nginx-conf: $(T)/nginx/conf/info
	@echo '## $@ ##'
	@$(call Status,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)
	@# TODO
	@#cat $< 
	@echo
	@#cat $(dir $<)/doc-$(notdir $<)
	@echo
	@#cat  $(dir $<)/headers-$(notdir $<)
	@echo



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
	@#$(call Status,$(dir $<)/headers-$(notdir $<),HTTP/2 200)
	@#$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),strict-transport-security)
	@#$(call HasHeaderKeyShowValue,$(dir $<)/headers-$(notdir $<),content-type)
	@# TODO
	@cat $<
	@cat $(dir $<)/doc-$(notdir $<)
	@cat $(dir $<)/headers-$(notdir $<)
	@docker logs or
	@docker logs xq

#TODO add more
# https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout

$(T)/site/home-page:
	@mkdir -p $(dir $@)
	@$(call GET,/,$@)





