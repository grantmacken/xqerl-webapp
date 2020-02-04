SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
########################################
include ../../.env
XQ := $(XQERL_CONTAINER_NAME)
DOMAIN = gmack.nz
T = response
xqAddress != docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
##################################################################
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
URL := http://$(xqAddress):$(XQERL_PORT)/$(DOMAIN)
GET = curl --silent --show-error \
 --write-out $(WriteOut) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)$1 > $2

##################################################################
# default - just run make
.PHONY: test
test: routes

.PHONY: routes
routes: home

.PHONY: clean
clean:
	@#echo '## $@ ##'
	@rm -f $(T)/routes/*

home: $(T)/routes/home
	@$(call ServesHeader,$(dir $<)/headers-$(notdir $<),HTTP/1.1 200 OK)

$(T)/routes/home:
	@mkdir -p $(dir $@)
	@$(call GET,/,$@)
