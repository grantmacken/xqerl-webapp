CODE_SRC :=  $(XQERL_HOME)/code/src

xqIPAddress = $(shell  docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ))
xqStatus != docker ps --filter name=$(XQ) --format 'status: {{.Status}}'
xqPortInUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+)8081->\K(8081)'

compile =  $(ESCRIPT) bin/scripts/compile.escript ./code/src/$1
compiledLibs := 'BinList = xqerl_code_server:library_namespaces(),\
 NormalList = [binary_to_list(X) || X <- BinList],\
 io:fwrite("~1p~n",[lists:sort(NormalList)]).'


define modulesHelp
===============================================================================
WORKING SITE: [ $(DOMAIN) ]
DIRECTORY:    [ modules ]

Since some modules may depend on other library module functions ,
libs must compiled in an ordered sequence
===============================================================================
endef


modules-help: export modulesHelp:=$(modulesHelp)
modules-help:
	echo "$${modulesHelp}"


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

.PHONY: escript
escript: 
	@echo '##[ $@ ]##'
	@$(ESCRIPT) bin/scripts/$(TARG).escript

.PHONY: xQinfo
xQinfo: 
	@#$(EVAL) 'xqerl_code_server:library_namespaces().'
	@#$(EVAL) 'xqerl_code_server:get_static_signatures().'
	@#$(EVAL) 'M = <<"Q{http://markup.nz/#newBase60}">>, xqerl_code_server:get_signatures(M).'
	@$(EVAL) 'M = <<"Q{http://markup.nz/#newBase60}">>, N = <<"newBase60">>, xqerl_code_server:get_function_signatures(M,N).'
	@$(EVAL) "newBase60:example()."

.PHONY: xQexec
xQexec: app/modules/getB60.xq
	@docker cp $< $(XQ):/tmp
	@$(EVAL) 'io:format(xqerl:run(xqerl:compile("/tmp/$(notdir $<)"))).'
	@#$(EVAL) 'xqerl:run("file____tmp_getB60.xq")'

.PHONY: xQrun
xQrun: 
	@#$(EVAL) 'M = <<"Q{http://markup.nz/#newBase60}">>, N = <<"newBase60">>, xqerl_code_server:get_function_signatures(M,N).'
	@#$(EVAL) 'xqerl_code_server:get_static_signatures().'
	@# $(EVAL) "xqerl:run(\"load-xquery-module('http://markup.nz/#newBase60')\")."
	@#$(EVAL) "xqerl:run(\"function-lookup(xs:QName('newBase60:encode'),1)\")."
	@#$(EVAL) "xqerl:run(\"function-name(http://markup.nz/#newBase60:encode#1)\")."
	@$(EVAL) "xqerl:run(\"function-name(newBase60:encode#1)\")."
	@$(EVAL) "xqerl:run(\"function-arity(newBase60:encode#1)\")."
	@#$(EVAL) "xqerl:run(\"function-apply(newBase60:encode#1,[19254])\")."
	@$(EVAL) "xqerl:run(\"QName('http://markup.nz/#newBase60','encode')\")."
	@$(EVAL) "xqerl:run(\"available-environment-variables()\")."
	@#$(EVAL) "xqerl:run(\"function-lookup(QName('http://markup.nz/#newBase60','encode'),1)\")."
	@#$(EVAL) "xqerl:run(\"function-lookup(QName('http://markup.nz/#newBase60','example'),2)\")."





.PHONY: app-info
app-info:
	@echo -n ' - date: '
	@$(EVAL) 'erlang:date().'
	@echo -n ' - cookie: '
	@$(EVAL) 'erlang:get_cookie().'
	@echo -n ' - nodes: '
	@$(EVAL) 'nodes(this).'
	@echo -n ' - node: '
	@$(EVAL) 'node().'
	@echo -n ' - ports: '
	@$(EVAL) 'erlang:ports().'
	@echo -n ' - self pid: '
	@$(EVAL) 'self().'
	@#echo -n ' - loaded: '
	@#$(EVAL) 'erlang:loaded().'
	@#echo -n ' - loaded: '
	@#$(EVAL) 'erlang:pre_loaded().'
	@echo -n ' - memory: '
	@$(EVAL) 'erlang:memory().'
	@echo -n ' - process_count: '
	@$(EVAL) 'erlang:system_info(process_count).'
	@echo -n ' net_admin:names - : '
	@$(EVAL) 'net_adm:names().'
	@echo -n ' net_admin:localhost - : '
	@$(EVAL) 'net_adm:localhost().'
	@echo -n ' net:if_names - : '
	@$(EVAL) 'net:if_names().'
	@echo -n ' init:get_status - : '
	@$(EVAL) 'init:get_status().'
	@echo -n ' init: - : '
	@$(EVAL) 'init:get_plain_arguments().'
	@$(EVAL) 'init:get_arguments().'
	@$(EVAL) 'registered().'


