
define help-nginx-configuration

produces: a docker volume containing my nginx configuration
used by:  running openresty container
-----------------------------------------------------------
Make targets
conf-build - build nginx conf files a copies them into a 
             docker volume named `nginx-configuration`


conf-deploy
 1. create 'tar' of the built `nginx-configuration` volume
 2. use 'gcloud' to secure copy 'tar' into GCE host
 3. use 'gcloud` to extract tar into GCE host docker volume named 'nginx-configuration'

 nginx configuration is now on GCE host as a *docker volume*,
 however it will not be live until we *restart* nginx

NOTE these actions should be able to be performed locally and by 
     github actions

endef
