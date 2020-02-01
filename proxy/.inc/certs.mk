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


alt-certsToHost:
	@# or just cat use the following certs
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


