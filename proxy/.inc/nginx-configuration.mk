
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
	@#$(if $(GITHUB_ACTIONS),docker cp $@ $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@) )
	@cp $< $@

$(B)/nginx/conf/%: conf/%
	@echo '## $(patsubst $(B)/%,%,$@) ##'
	@mkdir -p $(dir $@)
	@#$(if $(GITHUB_ACTIONS),,docker cp $@ $(OR):$(OPENRESTY_HOME)/$(patsubst $(B)/%,%,$@))
	@cp $< $@





