SHELL=/bin/bash
include ../../.env
DOMAIN = gmack.nz
T = .tmp
B = .build
# shortcut aliases
XQ := $(XQERL_CONTAINER_NAME)
DEX := docker exec $(XQ)
ESCRIPT := $(DEX) xqerl escript
EVAL := $(DEX) xqerl eval
OR := $(PROXY_CONTAINER_NAME)
DEO := docker exec $(OR)
STATIC_ASSETS :=  $(OPENRESTY_HOME)/nginx/html/$(DOMAIN)
# 
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"
# add includes
include ../../.inc/*
mpURL := https://$(DOMAIN)/micropub
mpJSON := $(mpURL) -H 'Content-Type: application/json' 

.PHONY: app
app: utilites publishing views routes

.PHONY: utilites
utilites: $(B)/modules/newBase60.xqm

.PHONY: views
views: $(B)/modules/render-feed.xqm $(B)/modules/render-note.xqm 

.PHONY: publishing
publishing: $(B)/modules/micropub.xqm

.PHONY: routes
routes: $(B)/modules/routes.xqm

PHONY: clean
clean: 
	@echo "## $(@) ##"
	@rm -rfv $(B)

.PHONY: icons
icons: $(patsubst  %.svg,$(B)/%.svgz,$(wildcard resources/icons/*.svg))

.PHONY: clean-icons
clean-icons:
	@rm -f $(patsubst  %.svg,$(B)/%.svgz,$(wildcard resources/icons/*.svg))
	@rm -fr $(T)/*

# STYLES: CASCADING STYLESHEETS

.PHONY: styles
styles: $(patsubst %.css,$(B)/%.css.gz,$(wildcard resources/styles/*.css))

.PHONY: clean-styles
clean-styles:
	echo '## $@ ##'
	@rm -f $(patsubst %.css,$(B)/%.css.gz,$(wildcard resources/styles/*.css))
	@rm -fr $(T)/*


#Creating a post using x-www-form-urlencoded syntax with one or more properties






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

