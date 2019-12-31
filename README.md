# xqerl-webapp
maybe a template for a xQuery webapp projects using xqerl, but just now an experiment

## Containers And Container Volumes

1. openresty (nginx) as a *cache*, *proxy*, and *static file* server  [ may use redis as cache server ]
2. xqerl resides behind our openresty proxy as an web application server

xqerl provides capabilities to handle structured marked up data resources like HTML, XML, JSON and CSV
 - a restXQ implementation:  providing an API interface to Create Retrieve Update Delete these resources in its internal data store.
 - a HTTP client:  ability to retrieve external resources 
 - an xQuery application engine: retrieve, query and transform data resources via xQuery

## Persistent Container Volumes

Since containers are ephemeral by nature, 
we provide volumes to persist data between stopping and starting the containers.
These volumes are in the 'docker-compose' file and their purpose should be self evident. 

## Setting Up the proxy server.

TODO!









