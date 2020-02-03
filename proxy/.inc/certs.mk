
#########################
### LETSENCRYPT CERTS ###
#########################
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(OR) --command 
mountCerts := type=bind,target=/tmp,source=$(CURDIR)/certs
mountGCE   := type=bind,target=/tmp,source=/home/$(GCE_NAME)/certs



.PHONY: modify-hosts-file
modify-hosts-file:
	@echo '## $@ ##'
	@sudo echo '127.0.0.1 $(TLS_COMMON_NAME)' | tee -a /etc/hosts
	@cat /etc/hosts | grep -oP '^127.0.0.1 $(TLS_COMMON_NAME)$$'
	@printf %60s | tr ' ' '-' && echo

LEpath  := $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)
CopyCerts = docker cp or:$(LEpath)/$(1).pem ./certs -L

.PHONY: certs-into-vol
certs-into-vol: certs-to-host
	@docker run --rm \
 --mount $(mountLetsencrypt) \
 --mount  $(mountCerts) \
 --entrypoint "sh" $(PROXY_DOCKER_IMAGE) -c \
 'mkdir -p $(LEpath) \
 && mv /tmp/dh-param.pem $(LETSENCRYPT)/ \
 && cp /tmp/* $(LEpath)/ '

.PHONY: certs-to-host
certs-to-host:
	@# or just cat use the following certs
	@#$(Gcmd) 'rm -rf certs'
	@$(Gcmd) 'mkdir -p certs \
 && $(call CopyCerts,cert)  \
 && $(call CopyCerts,fullchain)  \
 && $(call CopyCerts,chain)  \
 && $(call CopyCerts,privkey)  \
 && docker cp or:$(LETSENCRYPT)/dh-param.pem ./certs -L \
 && ls -al ./certs'
	@gcloud compute scp $(GCE_NAME):~/certs ./ --recurse
	@printf %60s | tr ' ' '-' && echo

.PHONY: certs-check
certs-check:
	@$(GCmd) 'ls -al $(LEpath)'
	@docker run --rm \
 --mount $(mountLetsencrypt) \
 --entrypoint "ls" $(PROXY_DOCKER_IMAGE) -alR  $(LETSENCRYPT)




