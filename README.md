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

<!--

WIP TODO: SECTIONS

## example: building a micropub server implementation 

## Using github actions


## Container Hosting 

  - Google Compute Engine (GCE)
  - ingress: controlling ports
  - using the gcloud client

## Proxy Server Container

 - CI pipeline setup on 'github actions'
 - a nginx configuration for generic routing via site domain 
 - secure setup
   - obtaining letsencrypt TLS certs with SNI certs 
   - TLS lockdown headers, rerouting port 80
   - OAuth2 Token Bearer authentication
 - generic proxy pass
 - cache server
 - static file server


## xqerl Web App

This repos web site development environment 
consist of the bundle of site **domains** I can manage 
under a TLS common name.

```
└── site
    ├── gmack.nz
    │   ├── Makefile
    │   ├── modules
    │   │   └── routes.xqm
    │   └── resources
    │       ├── icons
    │       │   ├── article.svg
    │       ├── images
    │       ├── scripts
    │       └── styles
    │           └── main.css
    ├── example.com
    ├── example2.com
```

A xqerl app consists of 
   - a module which establishes restXQ routes ( routes.xqm )
   - xQuery modules for querying, transforming, storing and viewing data resources

At the moment `site/gmack.nz` modules look like this

```
gmack.nz
├── Makefile
├── modules
│   ├── micropub.xqm
│   ├── newBase60.xqm
│   ├── render-feed.xqm
│   ├── render-note.xqm
│   └── routes.xqm
```

The build order of compiling is important,
as some xQuery modules depend upon others.

The build sequence, can be defined in the Makefile.

1. stand alone utility modules e.g.  newBase60
2. the publish libs that perform Create Retrieve Update Deletes operation on data
3. the render HTML view libs  
4. restXQ lib




To build the app...

```
cd site/gmack.nz
```


-->

