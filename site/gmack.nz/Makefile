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
STATIC_ASSETS :=  nginx/html/$(DOMAIN)
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"
mpURL := https://$(DOMAIN)/micropub
mpJSON := $(mpURL) -H 'Content-Type: application/json' 


####################################################################
# xQuery MODULES [ xqm ]
####################################################################

.PHONY: site
site: utilites publishing views routes

.PHONY: utilites
utilites: $(B)/modules/newBase60.xqm

.PHONY: views
views: $(B)/modules/render-feed.xqm $(B)/modules/render-note.xqm 

.PHONY: publishing
publishing: $(B)/modules/micropub.xqm

.PHONY: routes
routes: $(B)/modules/routes.xqm

.PHONY: clean-routes
clean-routes: 
	@rm -f $(B)/modules/routes.xqm

.PHONY: zadean
zadean: $(B)/modules/zadean-tests.xqm


$(B)/modules/%.xqm: modules/%.xqm
	@echo '##[ $* ]##'
	@mkdir -p $(dir $@)
	@rm -fr $(T)/*
	@docker cp $(<) $(XQ):$(CODE_SRC)
	@$(call compile,$(notdir $<)) | tee $(T)/compile_$(*).txt
	@cat $(T)/compile_$(*).txt | grep -q ':I:'
	@cp $< $@
	@echo;printf %60s | tr ' ' '-' && echo
	@$(EVAL) $(compiledLibs)
	@echo;printf %60s | tr ' ' '-' && echo

$(B)/app/modules/%.xq: app/modules/%.xq
	@echo '##[ $@ ]##'
	@mkdir -p $(dir $@)
	@docker cp $< $(XQ):/tmp
	@$(DEX) ls -al /tmp/$(notdir $<)
	@printf %60s | tr ' ' '-' && echo
	@$(EVAL) 'xqerl:compile("/tmp/$(notdir $<)").'
	@$(DEX) ls -al ./code/ebin
	@cp -v $(<) $(@)
	@echo;printf %60s | tr ' ' '-' && echo
	@$(EVAL) 'io:fwrite("~1p~n",[xqerl_code_server:library_namespaces()]).'
	@echo;printf %60s | tr ' ' '-' && echo

PHONY: clean-code
clean-code: 
	@echo "## $(@) ##"
	@
	@echo ' - remove the code volume '
	@pushd ../../ && \
 $(if $(xqStatus),docker-compose down, echo 'down') && \
 docker volume rm xqerl-compiled-code && \
 popd

PHONY: clean
clean: 
	@echo "## $(@) ##"
	@rm -rfv $(B)

### resources 

.PHONY: assets
assets: icons styles
	@docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets \
 --mount type=bind,target=/tmp,source=$(CURDIR)/$(B) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c 'cp -rv /tmp/$(DOMAIN) ./nginx/html/$(DOMAIN)'

.PHONY: remove-assets
remove-assets:
	echo '## $@ ##'
	@docker run --rm \
 --mount type=volume,target=$(OPENRESTY_HOME)/nginx/html,source=static-assets \
 --entrypoint "rm" $(PROXY_DOCKER_IMAGE) -rf ./nginx/html/$(DOMAIN)

####################################################################
# ICONS
####################################################################

.PHONY: icons
icons: $(patsubst  %.svg,$(B)/$(DOMAIN)/%.svgz,$(wildcard resources/icons/*.svg))

.PHONY: clean-icons
clean-icons:
	@rm -f $(patsubst  %.svg,$(B)/$(DOMAIN)/%.svgz,$(wildcard resources/icons/*.svg))
	@rm -fr $(T)/*

$(T)/$(DOMAIN)/resources/icons/%.svg: resources/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use scour to clean and optimize SVG'
	@cat $< | docker run \
  --rm \
  --name scour \
  --interactive \
docker.pkg.github.com/grantmacken/alpine-scour/scour:0.0.2 >  $@

$(B)/$(DOMAIN)/resources/icons/%.svgz: $(T)/$(DOMAIN)/resources/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use zopfli to compress image'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo " orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   scour size: [ $$(wc -c $(T)/resources/icons/$*.svg | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"

####################################################################
# STYLES: CASCADING STYLE SHEETS
####################################################################

.PHONY: styles
styles: $(patsubst %.css,$(B)/$(DOMAIN)/%.css.gz,$(wildcard resources/styles/*.css))

.PHONY: clean-styles
clean-styles:
	echo '## $@ ##'
	@rm -f $(patsubst %.css,$(B)/$(DOMAIN)/%.css.gz,$(wildcard resources/styles/*.css))
	@rm -fr $(T)/*

$(T)/$(DOMAIN)/resources/styles/%.css: resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use cssnano to reduce css file size'
	@cat $< | docker run \
  --rm \
  --init \
  --name cssnano \
  --interactive \
   docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 > $@

$(B)/$(DOMAIN)/resources/styles/%.css.gz: $(T)/$(DOMAIN)/resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use zopfli to gzip file'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo " orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "   cssnano size: [ $$(wc -c $(T)/resources/styles/$*.css | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"



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

