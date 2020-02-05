SHELL=/bin/bash
.ONESHELL:
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules
include ../.env
T := certbot

##################
### CERTBOT    ###
##################

COMMA := ,
EMPTY :=
SPACE := $(EMPTY) $(EMPTY)
DELIMIT := $(COMMA)$(EMPTY)
AUTHENTICATOR = webroot
OR := $(PROXY_CONTAINER_NAME)
Gcmd := gcloud compute ssh $(GCE_NAME) --command



define certbotConfig

rsa-key-size = 2048

# Uncomment and update to register with the specified e-mail address
email = $(GIT_EMAIL)

# Uncomment and update to generate certificates for the specified
# domains.
domains = $(subst ',,$(DOMAINS))

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

$(T)/letsencrypt.volume: $(T)/gce-host.uploaded
	@$(Gcmd) 'docker cp ~/cli.ini  $(OR):$(LETSENCRYPT)/' | tee $@

$(T)/gce-host.uploaded: $(T)/cli.ini
	@gcloud compute scp ./$< $(GCE_NAME):~/cli.ini 
	@$(Gcmd) 'ls -al cli.ini' | tee $@

$(T)/cli.ini: export certbotConfig:=$(certbotConfig)
$(T)/cli.ini:
	@mkdir -p $(dir $@)
	@echo "create cli config file"
	@echo "$${certbotConfig}" | tee $@

# home is on certbot container
# static-assets maps to $(OPENRESTY_HOME)/nginx/conf
mountNginxHtml  :=  type=volume,source=static-assets,target=/home
mountLetsencrypt := type=volume,source=letsencrypt,target=$(LETSENCRYPT)

.PHONY: certonly
certonly:
	# $(@) #
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot certonly \
 --dry-run'
 
 # --name certbot \
 # -v "letsencrypt:/etc/letsencrypt" \
 # -v "html:/home" \

.PHONY: renew
renew:
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 certbot/certbot renew --dry-run -w /home -d gmack.nz 

.PHONY: certs
certs:
	@$(Gcmd) 'docker run -t --rm \
  -v "letsencrypt:/etc/letsencrypt" \
  -v "static-assets:/home" \
 certbot/certbot certificates'

.PHONY: dates
dates:
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

.PHONY: ls
ls:
	@$(Gcmd) 'docker run -t --rm \
 --mount $(mountNginxHtml) \
 --mount $(mountLetsencrypt) \
 --network $(NETWORK) \
 --entrypoint "sh" \
 $(PROXY_DOCKER_IMAGE) -c ""'
