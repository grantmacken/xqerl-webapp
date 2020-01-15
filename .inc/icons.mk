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


$(T)/resources/icons/%.svg: resources/icons/%.svg
	@echo "##[ $* ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use scour to clean and optimize SVG'
	@cat $< | docker run \
  --rm \
  --name scour \
  --interactive \
docker.pkg.github.com/grantmacken/alpine-scour/scour:0.0.2 >  $@

$(B)/resources/icons/%.svgz: $(T)/resources/icons/%.svg
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
