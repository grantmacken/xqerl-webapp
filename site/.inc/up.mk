
xqAddress      := docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP '$(NETWORK)'
dkrPortInUse     != docker ps --format '{{.Ports}}' | grep -oP '^(.+)8081->\K(8081)'

MustHaveVolume = docker volume list --format "{{.Name}}" | grep -q $(1) || docker volume create --driver local --name $(1)

.PHONY: check-volumes
check-volumes:
	@$(call MustHaveVolume,xqerl-compiled-code)
	@$(call MustHaveVolume,xqerl-database)
	@$(call MustHaveVolume,static-assets)
	@# docker volume list  --format "{{.Name}}"
	@echo "[ $(VolumeList) ] OK! all volumes available"

.PHONY: check-network
check-network:
	@echo -n ' - $@  '
	@$(if $(dkrNetworkInUse),echo  '[ $(NETWORK) ] OK! can use ',docker network create $(NETWORK))

.PHONY: check-port
check-port:
	@echo -n ' - $@:  '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+)8081->\K(8081)' || echo  '[ 8081 ] OK! can use '

.PHONY: up
up: info

PHONY: info
info: run
	@echo '## $@ ##'
	@docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}'
	@docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'
	@echo -n '-    port: '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+):\K(\d{4})'
	@echo -n '- IP address: '
	@docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(XQ)
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


.PHONY: run
run: check-volumes check-network check-port
	@echo '##[ $@ ]##'
	@docker ps --filter name=$(XQ) --format '{{.Status}}' | grep -oP '^Up.+$$' || \
 docker run \
 --mount $(MountCode) \
 --mount $(MountData) \
 --mount $(MountBin) \
 --name  $(XQ) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_DOCKER_IMAGE)
	@sleep 3

.PHONY: down
down: 
	@echo '##[ $@ ]##'
	@docker ps --filter name=$(XQ) --format '{{.Status}}' | grep -oP '^Up.+$$' && docker stop $(XQ)
	@docker ps --all --filter name=$(XQ) --format '{{.Status}}' | grep -oP '^Exited.+$$' && docker rm $(XQ)
	@docker  ps --all





# grantmacken/alpine-xqerl:06e13fd0d9a897b26f3aa001be94e7ce9df10db8
# grantmacken/alpine-xqerl:64558530421e1bc53451754361282ac1dbea8b4f
#

