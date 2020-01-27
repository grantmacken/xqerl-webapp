include .env
XQ=$(XQERL_CONTAINER_NAME)
OR=$(PROXY_CONTAINER_NAME)
B := .build
T := .tmp

DEX  = docker exec $(XQ)
DEO  = docker exec $(OR)
EVAL = $(DEX) xqerl eval
ESCRIPT = $(DEX) xqerl escript

IPAddress = $(shell  docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ))
dkrStatus != docker ps --filter name=$(XQ) --format 'status: {{.Status}}'
dkrPortInUse != docker ps --format '{{.Ports}}' | grep -oP '^(.+)80->\K(80)'
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP "$(NETWORK)"

define Help
-------------------------------------------------------------------------------
make up: start running containers via docker-compose
make down: stop
-------------------------------------------------------------------------------
endef

define Debug
-------------------------------------------------------------------------------
$(CURDIR)

zqerl IP address: $(IPAddress)

current working domain: $(DOMAIN)
current xq module: [ $(restXQ) ]
library-modules-filtered: [ $(library-modules-filtered) ] 

-------------------------------------------------------------------------------
endef


help: export mkHelp=$(Help)
help:
	@echo "$${mkHelp}"

debug: export mkDebug=$(Debug)
debug:
	@echo "$${mkDebug}"

PHONY: up
up:
	@$(if $(dkrNetworkInUse),echo  '- NETWORK [ $(NETWORK) ] is available',docker network create $(NETWORK))
	@$(if $(dkrPortInUse), echo '- PORT [ 80 ] is already taken';false , echo  '- PORT [ 80 ] is available')
	@$(if $(dkrStatus), echo '$(dkrStatus)',docker-compose up -d && sleep 2)
	@$(if $$(docker ps --filter name=$(XQ) --format '{{.Names}}' | grep '$(XQ)'),,echo  '- container NOT running';false )
	@echo -n '- started: '
	@$(EVAL) 'application:ensure_all_started(xqerl).'
	@$(MAKE) -silent info
	@#cd site/$(DOMAIN) && $(MAKE) -silent xqm
	@#cd site/$(DOMAIN)/tests && $(MAKE) -silent test

.PHONY: down
down:
	@echo -e '##[ $@ ]##'
	@docker-compose down

compiledLibs := 'BinList = xqerl_code_server:library_namespaces(),\
 NormalList = [binary_to_list(X) || X <- BinList],\
 io:fwrite("~1p~n",[lists:sort(NormalList)]).'

PHONY: info
info:
	@echo '## $@ ##'
	@docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}'
	@docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'
	@echo -n '-    port: '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})'
	@echo -n '- IP address: $(IPAddress)'
	@echo;printf %60s | tr ' ' '-' && echo
	@echo -n '- working dir: '
	@$(EVAL) '{ok,CWD}=file:get_cwd(),list_to_atom(CWD).'
	@echo -n '-        node: '
	@$(EVAL) 'erlang:node().'
	@#$(EVAL) 'erlang:nodes().' 
	@echo -n '-      cookie: '
	@$(EVAL) 'erlang:get_cookie().'
	@echo -n '-        host: '
	@$(EVAL) '{ok, HOSTNAME } = net:gethostname(),list_to_atom(HOSTNAME).'
	@echo;printf %60s | tr ' ' '-' && echo
	@$(EVAL) $(compiledLibs)

watch:
	@while true; do \
        $(MAKE) --silent $(TARGET); \
        inotifywait -qre close_write .; \
    done

.PHONY: gcloud-init
gcloud-init:
	@echo '## $@ ##'
	@# set up volumes
	@gcloud compute ssh $(GCE_NAME) --command 'docker volume list'
	@#gcloud compute ssh $(GCE_NAME) --command 'docker volume create --driver local --name repo-owners-lualibs'
	@#gcloud compute ssh $(GCE_NAME) --command 'docker volume create --driver local --name static-assets'
	@#gcloud compute ssh $(GCE_NAME) --command 'docker volume create --driver local --name nginx-configuration'
	@#gcloud compute ssh $(GCE_NAME) --command 'docker volume create --driver local --name xqerl-database'
	@#gcloud compute ssh $(GCE_NAME) --command 'docker volume create --driver local --name xqerl-compiled-code'











