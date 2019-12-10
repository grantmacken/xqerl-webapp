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
domains = $(subst $(space),$(delimit)$(space),$(DOMAINS))

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
	@gcloud compute ssh $(HOST) --container or --command  'ls -al $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)'



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
