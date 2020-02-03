
#######################
# GCLOUD DEPLOYMENT ###
#######################
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(XQ) --command 

.PHONY: gcloud-conf-volume-deploy
gcloud-conf-volume-deploy: $(D)/nginx-configuration.tar
	@# make sure we have a deploy directory on the host
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@# copy into GCE host
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@#gcloud compute ssh $(GCE_NAME) --command  'ls -al ./deploy'
	@# extract tar into volume
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(mountNginxConf) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'

GcloudVolumeCreate = grep -q $(1) $(2) || $(Gcmd) 'docker volume create --driver local --name $(1)'

.PHONY: gcloud-check-volumes
gcloud-check-volumes: $(D)/gcloud-volume-check.txt
	@$(foreach volume,$(VolumeList),$(call GcloudVolumeCreate,$(volume),$(<)))

$(D)/gcloud-volume-check.txt: 
	@mkdir -p $(dir $@)
	@$(Gcmd) 'docker volume list  --format "{{.Name}}"' > $@

.PHONY: gcloud-proxy-up
gcloud-proxy-up: 
	@echo '##[ $@ ]##'
	@$(Gcmd) 'docker ps --filter name=$(OR) --format "{{.Status}}"' | grep -q Up || $(Gcmd) '$(dkrRun)'
	@sleep 2
	@$(Gcmd) 'docker ps --filter name=$(OR) --format "{{.Status}}"'
	@$(Gcmd) 'docker logs $(OR)'

