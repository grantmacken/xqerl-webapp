define stylesHelp
===============================================================================
STYLES : working with styles
 - css
 Workin folder: 'resources/styles'

< src styles
[ postproccess ] postcss - autoprefixer, cssnano (minify, remove comments etc)
[ build ] zopfli gzipped css files into build dir
[ upload ] store into eXist dev server
[ reload ] TODO!  trigger live reload
[ check ]  with prove run functional tests
- use Curl to check if serving gzipped file via gzip-static nginx declaration
- use Curl check if serving unzipped file via gunzip nginx declaration

=============================================================================

Tools Used:
[zopfli](https://github.com/google/zopfli) :              to gzip 
[postcss-cli](https://github.com/pirxpilot/postcss-cli):  to run
 - [autoprefixer](https://github.com/postcss/autoprefixer)
 - [cssnano](http://cssnano.co/optimisations)
 - and maybe some other stuff

`make styles`
`make watch-styles`
`make styles-help`

 1. styles 
 2. watch-styles  ...  watch the directory
  'make styles' will now be triggered by changes in dir
endef


styles-help: export stylesHelp:=$(stylesHelp)
styles-help:
	echo "$${stylesHelp}"

$(T)/resources/styles/%.css: resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@[ -d $(dir $@) ] || mkdir -p $(dir $@)
	@echo  ' - use cssnano to reduce css file size'
	@cat $< | docker run \
  --rm \
  --init \
  --name cssnano \
  --interactive \
   docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 > $@


$(B)/resources/styles/%.css.gz: $(T)/resources/styles/%.css
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

xxxasasa:
	@zopfli $(T)/$(notdir $<) &&  echo -e ' - gziped with zopfli' || false
	@echo  "  gzip bld size: [ $$(wc -c  $(T)/$(notdir $@)  | cut -d' ' -f1) ]"
	@echo  ' - copy local files: [ $(T)/$(notdir $@) $(T)/$(notdir $<) ] '
	@echo  '     into conatiner: [ $(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@)) ] '
	@$(DEO) mkdir -p $(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@))
	@docker cp $(T)/$(notdir $<) or:$(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@))
	@docker cp $(T)/$(notdir $@) or:$(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@))
	@$(DEO) ls $(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@)) | grep -q $(notdir $@) 
	@$(DEO) ls $(STATIC_ASSETS)/$(patsubst $(B)/%,%,$(dir $@)) | grep -q $(notdir $<) 
	@rm $(T)/$(notdir $<)
	@mkdir  -p $(dir $@)
	@mv $(T)/$(notdir $@) $@
	@echo "========================================================="

