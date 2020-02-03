
#################################################
### OPENRESTY UP DOWN RESTART and TEST CONFIG ###
#################################################

orAddress      := docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(OR)
dkrNetworkInUse != docker network list --format '{{.Name}}' | grep -oP '$(NETWORK)'

MustHaveVolume = docker volume list --format "{{.Name}}" | grep -q $(1) || docker volume create --driver local --name $(1)

.PHONY: check-volumes
check-volumes:
	@$(call MustHaveVolume,nginx-configuration)
	@$(call MustHaveVolume,static-assets)
	@$(call MustHaveVolume,letsencrypt)
	@$(call MustHaveVolume,site-lualib)
	@#docker volume list  --format "{{.Name}}"


$(T)/volume-check.txt: 
	@mkdir -p $(dir $@)
	@docker volume list  --format "{{.Name}}" > $@

.PHONY: check-network
check-network:
	@echo -n ' - $@  '
	@$(if $(dkrNetworkInUse),echo  '[ $(NETWORK) ] OK! can use ',docker network create $(NETWORK))

.PHONY: check-port
check-port:
	@echo -n ' - check TLS port '
	@docker ps --format '{{.Ports}}' | grep -oP '^(.+)443->\K(443)' || echo  '[ 443 ] OK! can use.'

.PHONY: up
up: check-volumes check-network check-port
	@echo -n ' - start container instance '
	@echo 'TODO - check letsencypt certs in "letsencrypt" volume'
	@docker ps --filter name=$(OR) --format '{{.Status}}' | grep -oP '^Up.+$$' || \
 docker run  \
 --mount $(mountNginxConf) \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --mount $(mountSiteLualib) \
 --name  $(OR) \
 --hostname openresty \
 --network $(NETWORK) \
 --publish 80:80 \
 --publish 443:443 \
 --detach \
 $(PROXY_DOCKER_IMAGE)

.PHONY: down
down: 
	@echo '##[ $@ ]##'
	@docker ps --filter name=$(OR) --format '{{.Status}}' | grep -oP '^Up.+$$' && docker stop $(OR)
	@docker ps --all --filter name=$(OR) --format '{{.Status}}' | grep -oP '^Exited.+$$' && docker rm $(OR)
	@docker  ps --all
	@rm -f $(T)/*

.PHONY: restart
restart:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec or ./bin/openresty -t
	@echo ' - local restart'
	@#docker exec or kill -HUP 1
	@docker exec or ./bin/openresty -s reload
	@#docker exec or openresty start
	@#docker ps | grep 'openresty'

.PHONY: config-test
config-test:
	@echo "## $@ ##"
	@echo ' - local test nginx configuration'
	@docker exec -t or openresty -t

.PHONY: info
info: $(T)/log-status

$(T)/log-status:
	@echo "## $@ ##"
	@mkdir -p $(T)
	@docker ps --all 
	@docker ps --filter name=$(OR) --format '  name: {{.Names}}' > $@
	@docker ps --filter name=$(OR) --format  'status: {{.Status}}'  >> $@
	@docker ps --filter name=$(OR) --format '  ports:  {{.Ports}}' >> $@
	@docker inspect --format='IP addr {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(OR) >> $@
	@cat $@


.PHONY: info2
info2: $(T)/versionInfo
	@docker exec -t or openresty -t
	@docker exec -t or openresty -v
	@echo 'nginx modules'
	@grep -oP '^..add.module.+$$' $< 
	@echo 'nginx compiled with'
	@grep -oP '^..with-[\w+-_]+$$' $< 


$(T)/versionInfo:
	@mkdir -p $(dir $@)
	@docker exec -t or openresty -V > $@





