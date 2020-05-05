SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include ../.env
B := .build

##################
### CERTBOT    ###
##################

COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DELIMIT := $(COMMA)$(EMPTY)
AUTHENTICATOR = webroot
Gcmd := gcloud compute ssh $(GCE_NAME) --command
Gcc  := gcloud compute ssh $(GCE_NAME) --container $(PROXY_CONTAINER_NAME) --command 
# home is on certbot containwe
# static-assets maps to $(OPENRESTY_HOME)/nginx/conf
mountNginxHtml  :=  type=volume,source=static-assets,target=/home
mountLetsencrypt := type=volume,source=letsencrypt,target=$(LETSENCRYPT)

define certbotConfig

rsa-key-size = 2048

# Uncomment and update to register with the specified e-mail address
email = $(GIT_EMAIL)

# Uncomment and update to generate certificates for the specified
# domains.
domains = $(DOMAINS)

# use a text interface instead of ncurses
text = true

# use the webroot authenticator.
# set path to the default html dir
authenticator = $(AUTHENTICATOR)
webroot-path = /home
agree-tos = true
eff-email = true
logs-dir = /home
endef

.PHONY: clean
clean:
	@find $(B)/ -type f | xargs rm -f

init: $(B)/letsencrypt.volume
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 --entrypoint "sh" \
 $(PROXY_DOCKER_IMAGE) -c "cat $(LETSENCRYPT)/cli.ini"'

$(B)/letsencrypt.volume: $(B)/gce-host.uploaded
	@$(Gcmd) 'docker cp ~/cli.ini  $(PROXY_CONTAINER_NAME):$(LETSENCRYPT)/' | tee $@

$(B)/gce-host.uploaded: $(B)/cli.ini
	@gcloud compute scp ./$< $(GCE_NAME):~/cli.ini 
	@$(Gcmd) 'ls -al cli.ini' | tee $@

$(B)/cli.ini: export certbotConfig:=$(certbotConfig)
$(B)/cli.ini:
	@mkdir -p $(dir $@)
	@echo "create cli config file"
	@echo "$${certbotConfig}" | tee $@

.PHONY: certonly
certonly:
	# $(@) #
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot certonly --expand'


.PHONY: dry-run
dry-run:
	# $(@) #
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot certonly --dry-run --expand'

.PHONY: reload
reload: 
	@$(Gcc) './sbin/nginx -s reload'


.PHONY: renew
renew: nginx.reload

nginx.reload: certs.renew
	@grep -oP 'Cert not yet due for renewal' $< || \
 $(Gcc) './sbin/nginx -s reload' | tee $@

certs.renew:
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot renew' | tee $@

.PHONY: certs
certs:
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot certificates'

.PHONY: dig
dig:
	@#dig gmack.nz +nocmd +nostats +noquestion
	@echo '+++++++++++++++++++++++++++++++++++++++++++++++++++'
	@dig @ns-cloud-d1.googledomains.com $(SUBDOMAIN) | grep status
	@echo '+++++++++++++++++++++++++++++++++++++++++++++++++++'
	@echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
	@dig @208.67.222.222 $(SUBDOMAIN) | grep status
	@echo 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'

.PHONY: openssl-sni
openssl-sni:
	@openssl s_client -servername $(TLS_COMMON_NAME) -tlsextdebug -msg -connect $(SUBDOMAIN):443
	@2>&1 openssl s_client -connect $(TLS_COMMON_NAME):443 | openssl x509 -noout -text | grep -oP '^\s+\KDNS:.+'

.PHONY: openssl-dates
openssl-dates:
	@echo | openssl s_client -connect $(TLS_COMMON_NAME):443 2>/dev/null | openssl x509 -noout -dates

define certsHelp
```
runs on gihub actions
```
name: certbot-init
on:
  push:
    branches:
      - certbot/init
```

git checkout -b certbot/init

```
make certsRenew INC=certs
make certsToLocal
```

endef

mkCertsHelp: export mkCertsHelp=$(certsHelp)
mkCertsHelp:
	@echo "$${mkCertsHelp}"


