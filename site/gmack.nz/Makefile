SHELL=/bin/bash
include ../../.env
T = .tmp
B = .build
DOMAIN=gmack.nz
OR := $(PROXY_CONTAINER_NAME)
DEO := docker exec $(OR)
STATIC_ASSETS :=  $(OPENRESTY_HOME)/nginx/html/$(DOMAIN)

dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"

include ../../.inc/*

mpURL := https://$(DOMAIN)/micropub
mpJSON := $(mpURL) -H 'Content-Type: application/json' 

.PHONY: feed
feed: $(B)/modules/render-feed.xqm



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

