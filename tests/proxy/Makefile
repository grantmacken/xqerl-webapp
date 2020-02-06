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

fHeader = $(patsubst %/$(1),%/headers-$(1),$(2))

# 1=file 2=headerKey
HasHeaderKey  = grep -q '^$(2)' $(1) 
# 1=file 2=key 3=value
HasKeyValue   = grep -oP '^$2: \K(.+)$$' $1 | grep -q '^$3'
#

HeaderKeyValue =  echo "$$( grep -oP '^$2: \K(.+)$$' $1 )"


ServesHeader   = if $(call HasHeaderKey,$1,$2); \
 then $(call Tick, '- header [ $2 ] ');echo $3;true; \
 else $(call Cross,'- header [ $2 ] ');echo $3;false;fi

DoesNotServeHeader   = if $(call HasHeaderKey,$1,$2); \
 then $(call Cross, '- should not serve header [ $2 ] ') \
 else $(call Tick,  '- does not server header [ $2 ] ');;echo fi

HasHeaderKeyShowValue = \
 if $(call HasHeaderKey,$1,$2);then $(call Tick, "- header $2: " );$(call HeaderKeyValue,$1,$2);\
 else $(call Cross, "- header $2: " );false;fi

ServesContentType = if $(call HasHeaderKey,$(1),$(2)); then \
 if $(call HasKeyValue,$1,$2,$3); \
 then $(call Tick, '- header [ $2 ] should have value [ $3 ] ');echo ;true; \
 else $(call Cross,'- header [ $2 ] should value [ $3 ] ');echo;false;fi\
 else $(call Cross,'- header [ $2 ] should have value [ $3 ] ');echo;false;fi

# if $(call HasKeyValue,$1,$2) ; then echo $2; else echo 'no';fi\
# echo '$1 $2 $3

# if $(call HasHeaderKey,$1,$2); then \
#   $(call HasKeyValue,$(1),$(2),$(3),$(4)) \
# else $(call Cross,'- header [ $2 ] ');echo $3;false;fi



##################################################################
# https://ec.haxx.se/usingcurl/usingcurl-verbose/usingcurl-writeout

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

binGET = curl --silent --show-error \
 --resolve $(DOMAIN):443:$(orAddress) \
 -H 'Host: $(DOMAIN)' \
 --write-out $(WriteOut) \
 --dump-header $(dir $2)/headers-$(notdir $2) \
 --output $(dir $2)/doc-$(notdir $2) \
 $(URL)$1 > $2 


######################################
# Common Messages

######################################


.PHONY: test
test: clean routes icons

.PHONY: clean
clean: 
	@rm -r $(T)/* || echo

include routes.mk icons.mk
