
# GCLOUD DEPLOYMENT
Gcmd := gcloud compute ssh $(GCE_NAME) --command
GCmd := gcloud compute ssh $(GCE_NAME) --container $(XQ) --command 

#  gcloud volumes
GcloudVolumeCreate = grep -q $1 $(2) || $(Gcmd) 'docker volume create --driver local --name $(1)'; 

.PHONY: gcloud-check-volumes
	@$(Gcmd) '$(call MustHaveVolume,xqerl-compiled-code)'
	@$(Gcmd) '$(call MustHaveVolume,xqerl-database)'
	@$(Gcmd) '$(call MustHaveVolume,static-assets)'

# this is call from github action but may be called locally
.PHONY: gcloud-code-volume-deploy
gcloud-code-volume-deploy: $(D)/xqerl-compiled-code.tar
	@# make sure we have a deploy directory on the host
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@# copy into GCE host
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@# extract tar into volume
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(MountCode) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(XQERL_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'

# make sure running

.PHONY: gcloud-xqerl-up
gcloud-xqerl-up:
	@echo '##[ $@ ]##'
	@gcloud compute ssh $(GCE_NAME) --command 'docker ps --filter name=$(OR) --format "{{.Status}}"' | \
 grep -q Up || \
 gcloud compute ssh $(GCE_NAME) --command \
 'docker  run \
 --mount $(MountCode) \
 --mount $(MountData) \
 --name  $(XQERL_CONTAINER_NAME) \
 --hostname xqerl \
 --network $(NETWORK) \
 --publish $(XQERL_PORT):$(XQERL_PORT) \
 --detach \
 $(XQERL_DOCKER_IMAGE)' 
	@sleep 2
	@gcloud compute ssh $(GCE_NAME) --command 'docker ps --filter name=$(OR)'

.PHONY: gcloud-code-compile
gcloud-code-compile: $(DeployList)

# this is called when xqerl is running
# not sure why I have to do this as code is already compiled

$(D)/modules/%.xqm: $(B)/modules/%.xqm
	@echo '##[ $* ]##'
	@mkdir -p $(dir $@)
	@gcloud compute ssh $(GCE_NAME) \
 --container '$(XQ)' \
 --command \
 'xqerl eval "xqerl:compile(\"code/src/$(notdir $@)\")"'
	@cp $< $@

PHONY: gcloud-xqerl-info
gcloud-xqerl-info:
	@echo '## $@ ##'
	@$(Gcmd) \
 "docker ps --filter name=$(XQ) --format ' -    name: {{.Names}}' && docker ps --filter name=$(XQ) --format ' -  status: {{.Status}}'"

PHONY:gcloud-show-lib-namespaces
gcloud-show-lib-namespaces:
	@$(GCmd) \
 "xqerl eval 'xqerl_code_server:library_namespaces()'"

.PHONY: gcloud-assets-volume-deploy
gcloud-assets-volume-deploy: $(D)/static-assets.tar
	@gcloud compute ssh $(GCE_NAME) --command  'mkdir -p $(D)'
	@gcloud compute scp $< $(GCE_NAME):~/$(D)
	@gcloud compute ssh $(GCE_NAME) --command \
 'docker run --rm \
 --mount $(MountAssets) \
 --mount type=bind,target=/tmp,source=/home/$(GCE_NAME)/$(D) \
 --entrypoint "tar" $(PROXY_DOCKER_IMAGE) xvf /tmp/$(notdir $<) -C /'

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

