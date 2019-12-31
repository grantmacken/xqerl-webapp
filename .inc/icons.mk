define iconHelp
===============================================================================


===============================================================================

 ICONS is the working directory for svg icons
 Since we are using HTTP/2 which muliplexes requests we will not create sprites 
each icon in resourse icons id optimised delivered to build dir, then uploaded 
to xqerl
    < src icons 
     [ xmllint ]  check if well formed
     [ optimise ] use scour to convert to svgz and output to
     [ build ]    icons in  build.icons dir
     [ upload ]   store into eXist dev server
     [ reload ]   TODO!  trigger live reload
     [ check ]    with prove run functional tests
=============================================================================

   https://github.com/scour-project/scour
 Notes: path always relative to root

`make icons`
`make watch-icons`
`make help-icons`

 1. icons 
 2. watch-styles  ...  watch the directory
  'make icons' will now be triggered by changes in dir
endef

icons-help: export iconHelp:=$(iconHelp)
icons-help:
	echo "$${iconHelp}"

.PHONY: icons
icons: $(patsubst  %.svg,$(B)/%.svgz,$(wildcard resources/icons/*.svg))

clean-icons:
	@rm -f $(patsubst  %.svg,$(B)/%.svgz,$(wildcard resources/icons/*.svg))

$(B)/resources/icons/%.svgz: resources/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@rm -fr $(T)/*
	@# mkdir -p $(patsubst %,t/%,$(dir $<))
	@echo -en ' - use xmllint check if SVG document well formed'
	@[ -z $(shell xmllint --noout $<) ] && echo -e ' [ OK! ]'
	@echo -e ' - use scour to optimise and create zipped file'
	@scour -i $< -o  $(T)/$(notdir $@)\
 --enable-viewboxing \
 --enable-id-stripping \
 --enable-comment-stripping \
 --shorten-ids \
 --indent=none >/dev/null
	@echo -e "      orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo -e "gzipped scour size: [ $$(wc -c $(T)/$(notdir $@) | cut -d' ' -f1) ]"
	@$(DEO) mkdir -p $(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@))
	@docker cp $(T)/$(notdir $@) or:$(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@))
	@$(DEO) ls $(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@)) | grep -q $(notdir $<) 
	@mv $(T)/$(notdir $@) $@
	@echo "========================================================="
