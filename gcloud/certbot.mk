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

define certsHelp
```
make [target] INC=certbot
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
authenticator = $(AUTHENTICATOR)
webroot-path = /home
agree-tos = true
eff-email = true
logs-dir = /home
endef

$(T)/into-letsenypt.vol: $(T)/ini-into-host.uploaded
	$(Gcmd) 'docker cp ~/cli.ini  or:/etc/letsencrypt/'


$(T)/ini-into-host.uploaded: $(T)/cli.ini
	@gcloud compute scp ./$< $(GCE_NAME):~/cli.ini 
	@$(Gcmd) 'ls -al cli.ini' | tee $@
	@gcloud compute ssh gmack --command 'docker cp ~/cli.ini  $(OR):$(LETSENCRYPT)/' | tee $@


$(T)/cli.ini: export certbotConfig:=$(certbotConfig)
$(T)/cli.ini:
	@[ -d  $(dir $@) ] || mkdir $(dir $@)
	@echo "create cli config file"
	@echo "$${certbotConfig}" | tee $@

cbConfig: $(T)/cli.ini

cbConfigClean:
	@rm $(T)/cli.ini




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
