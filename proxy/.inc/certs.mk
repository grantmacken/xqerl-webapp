
#########################
### LETSENCRYPT CERTS ###
#########################
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(OR) --command 
mountCerts := type=bind,target=/tmp,source=$(CURDIR)/certs
mountGCE   := type=bind,target=/home,source=/home/$(GCE_NAME)/certs

.PHONY: certs-to-host
certs-to-host: certs/letsencrypt.tar
	@echo ' - on local host extract letsencrypt.tar into "letsencypt" volume' 
	@docker run --rm \
 --mount $(mountLetsencrypt) \
 --mount $(mountCerts) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /
	@rm -fr $(dir $<)

certs/letsencrypt.tar:
	@mkdir -p $(dir $@)
	@echo ' - on GCE host tar "$(OR)" volume into host dir' 
	@$(Gcmd) 'docker run --rm \
 --volumes-from $(OR) \
 --mount $(mountGCE) \
 alpine:3.11 tar -czf /home/letsencrypt.tar $(LETSENCRYPT)'
	@echo -n ' - fetching tar from GCE host to local host: '  
	@gcloud compute scp $(GCE_NAME):~/certs ./ --recurse
	@#mv certs $(B)/

.PHONY: modify-hosts-file
modify-hosts-file:
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


