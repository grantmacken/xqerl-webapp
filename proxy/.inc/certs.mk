#########################################################
# SSL CONFIG note
# can not be done on local dev server
# MYDOMAIN is read for config at root
#########################################################

HOST := $(GCE_NAME)

define certsHelp
```
make [target] INC=certs
```

## To renew certs

```
make certsRenew INC=certs
make certsToLocal
```

endef

mkCertsHelp: export mkCertsHelp=$(certsHelp)
mkCertsHelp:
	@echo "$${mkCertsHelp}"


define certbotConfig

rsa-key-size = 2048

# Uncomment and update to register with the specified e-mail address
email = $(GIT_EMAIL)

# Uncomment and update to generate certificates for the specified
# domains.
domains = $(subst $(SPACE),$(DELIMIT)$(SPACE),$(DOMAINS))

# use a text interface instead of ncurses
text = true

# use the webroot authenticator.
# set path to the default html dir
authenticator = webroot
webroot-path = /home
agree-tos = true
eff-email = true
logs-dir = /home
endef

cbConfig: $(T)/cli.ini

cbConfigClean:
	@rm $(T)/cli.ini


$(T)/cli.ini: export certbotConfig:=$(certbotConfig)
$(T)/cli.ini:
	@[ -d  $(dir $@) ] || mkdir $(dir $@)
	@echo "create cli config file"
	@echo "$${certbotConfig}" | tee  $@
	@gcloud compute scp ./$@ gmack:~/cli.ini
	@gcloud compute ssh gmack --command 'docker cp ~/cli.ini  or:/etc/letsencrypt/'
	@gcloud compute ssh gmack --command 'docker exec or cat /etc/letsencrypt/cli.ini'

.PHONY: certbotCertOnly
certbotCertOnly:
	# $(@) #
	@gcloud compute ssh gmack --command 'docker run -t --rm --name certbot \
 -v "letsencrypt:/etc/letsencrypt" \
 -v "html:/home" \
 certbot/certbot certonly'

.PHONY: certsRenew
certsRenew:
	# $(@) #
	@gcloud compute ssh gmack  --command \
 'docker run -t --rm --name certbot \
 -v "letsencrypt:/etc/letsencrypt" \
 -v "html:/home" \
 certbot/certbot renew'

.PHONY: certsToHost
certsToHost:
	@echo '## $@ ##'
	@mkdir -p ./certs
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm --volumes-from or -v /tmp:/tmp alpine:3.11 tar cvf /tmp/letsencrypt.tar $(LETSENCRYPT)'
	@#gcloud compute ssh $(GCE_NAME) --command 'ls /tmp'
	@gcloud compute scp  $(GCE_NAME):/tmp/letsencrypt.tar ./certs/
	@#ls -al ./certs
	@docker volume create --driver local --name letsencrypt
	@docker run --rm \
 --mount type=volume,target=$(LETSENCRYPT),source=letsencrypt \
 --mount type=bind,target=/tmp,source=$(CURDIR)/certs \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/letsencrypt.tar -C /

.PHONY: hostsFile
hostsFile:
	@echo '## $@ ##'
	# adjust hosts file TODO all domains
	@echo "127.0.0.1  $(TLS_COMMON_NAME)" | sudo tee -a /etc/hosts
	@cat /etc/hosts
	@printf %60s | tr ' ' '-' && echo


x-certsToHost:
	@gcloud compute ssh $(GCE_NAME) --command 'mkdir -p ./live/$(TLS_COMMON_NAME)'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/cert.pem ./live/$(TLS_COMMON_NAME) -L'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem ./live/$(TLS_COMMON_NAME) -L'
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem ./live/$(TLS_COMMON_NAME) -L'
	# dh param in different location
	@gcloud compute ssh $(GCE_NAME) --command  'docker cp or:$(LETSENCRYPT)/dh-param.pem ./live/$(TLS_COMMON_NAME) -L'
	@gcloud compute ssh $(GCE_NAME) --command 'ls -al ./live/$(TLS_COMMON_NAME)'
	@echo '---------------------------------------------------------------------'
	@mkdir -p $(B)
	@#sudo chown ${USER} $(B)/certs
	@gcloud compute scp  $(GCE_NAME):~/live $(B) --recurse
	# clean up on GCE Host
	@gcloud compute ssh $(GCE_NAME) --command 'rm -r ./live'
	# relocate dh param
	@# mv $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/dh-param.pem $(LETSENCRYPT)/dh-param.pem
	@ls -alR $(B)
	@echo '---------------------------------------------------------------------'
	@#ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	# create letsencrypt volume
	@docker volume create --driver local --name letsencrypt
	# create a dummy container and attach to letsencypt volume
	@docker run --rm --name dummy --detach \
 --mount type=volume,target=$(LETSENCRYPT),source=letsencrypt \
 --entrypoint "/usr/bin/tail" $(PROXY_DOCKER_IMAGE)  -f /dev/null
	# copy retrieved certs into letsencrypt volume
	@docker exec dummy mkdir -p $(LETSENCRYPT)/live
	@docker cp $(B)/live/$(TLS_COMMON_NAME) dummy:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@docker exec dummy mv $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/dh-param.pem ../../
	# view created items
	@echo '---------------------------------------------------------------------'
	@docker exec dummy ls -al $(LETSENCRYPT) | grep 'dh-param.pem'
	@docker exec dummy ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@echo '---------------------------------------------------------------------'
	@docker stop dummy
	# adjust hosts file TODO all domains
	@echo "127.0.0.1  $(TLS_COMMON_NAME)" | sudo tee -a /etc/hosts
	@printf %60s | tr ' ' '-' && echo

.PHONY: certsToLocal
certsToLocal:
	# $(@) #
	@gcloud compute ssh gmack --container or --command \
 'ls -al /etc/letsencrypt/live/$(TLS_COMMON_NAME)'
	@echo ' - copy from remote container into remote host file system'
	@gcloud compute ssh gmack --command 'mkdir -p ./certs'
	@gcloud compute ssh gmack --command  'docker cp or:$(LETSENCRYPT)/dh-param.pem ~/certs -L'
	@gcloud compute ssh gmack --command  'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem ~/certs -L'
	@gcloud compute ssh gmack --command 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem ~/certs -L'
	@gcloud compute ssh gmack --command 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem ~/certs -L'
	@gcloud compute ssh gmack --command 'docker cp or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/cert.pem ~/certs -L'
	@gcloud compute scp  gmack:~/certs ./$(T) --recurse
	@docker exec or mkdir -p $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@docker exec or ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@docker cp ./$(T)/certs/dh-param.pem  or:$(LETSENCRYPT)
	@docker cp ./$(T)/certs/chain.pem  or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@docker cp ./$(T)/certs/fullchain.pem  or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@docker cp ./$(T)/certs/privkey.pem  or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@docker cp ./$(T)/certs/cert.pem  or:$(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
	@docker exec or ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)

xxxxxx:
	@$(SSH) 'docker exec or cat /etc/letsencrypt/live/$(TLS_COMMON_NAME)/README'
	@echo ' - copy from remote container into remote host file system'
	@$(SSH) 'docker cp or:/etc/letsencrypt ~/'
	@echo ' - copy from remote host file system into local file system'
	@gcloud compute scp  gmack:~/letsencrypt /etc/ --recurse
	@echo ' - copy from local file system into local container'
	@docker cp /etc/letsencrypt or:/etc/
