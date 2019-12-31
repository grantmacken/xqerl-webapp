# xqerl-webapp
maybe a template for a xQuery webapp projects using xqerl, but just now an experiment

## Containers And Container Volumes

1. openresty (nginx) as a *cache*, *proxy*, and *static file* server  [ may use redis as cache server ]
2. xqerl resides behind our openresty proxy as an web application server

xqerl provides capabilities to handle structured marked up data resources like HTML, XML, JSON and CSV
 - a restXQ implementation providing an API interface to Create Retrieve Update Delete these resources in its internal data store.
 - a HTTP client giving the ability to retrieve external and internal network resources 
 - an xQuery application engine to retrieve, query and transform data resources via the *functional*, *typed* **xQuery** language

Since containers are ephemeral by nature, 
we provide volumes to persist data between stopping and starting the containers.
These volumes are in the 'docker-compose' file and their purpose should be self evident.


WIP TODO: SECTIONS

## example: building a micropub server implementation 

## Using github actions


## Setting Up Container Hosting 

- Google Compute Engine (GCE)
  - ingress: controlling ports
  - gcloud client

## Setting Up Proxy Server
  - obtaining letsencrypt TLS certs
  - TLS lockdown 
  - SNI capabilities: routing via domain
  - OAuth2 Token Bearer authentication
  - cache server
  - static file server


## Setting Up xqerl 






