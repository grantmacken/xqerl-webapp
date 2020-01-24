
$(B)/nginx/conf/%: conf/%
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@docker cp $< $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@)
	@cp $< $@

define mkCertsConf
# My LETSENCRYPT certs
ssl_certificate         $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/fullchain.pem;
ssl_certificate_key     $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/privkey.pem;
ssl_trusted_certificate $(LETSENCRYPT)/live/$(TLS_COMMON_NAME)/chain.pem;
endef

$(B)/nginx/conf/certs.conf: export mkCertsConf:=$(mkCertsConf)
$(B)/nginx/conf/certs.conf:
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@echo "$${mkCertsConf}" > $@
	@docker cp $@ $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@)



# define mkDockerfile
# FROM  $(PROXY_IMAGE_FROM) as proxy
# RUN  rm $(OPENRESTY_HOME)/nginx/conf/*
# COPY ./nginx/conf  $(OPENRESTY_HOME)/nginx/conf
# # add env vars
# ENV PROXY_CONTAINER_NAME $(PROXY_CONTAINER_NAME)
# ENV XQERL_CONTAINER_NAME $(XQERL_CONTAINER_NAME)
# ENV XQERL_PORT $(XQERL_PORT)
# endef



