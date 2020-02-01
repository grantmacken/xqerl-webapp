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

# WIP! Some notes below

## Using docker-compose

The docker-compose tooling consists of 2 files

 1. docker-compose.yml
 2. .env

 docker-compose will bring your local container environment up 

 1. images: start up containers in right order - xqerl before nginx
 2. volumes: preference for portable named volumes over bind volumes
             the only thing we bind is the xqerl `./bin` dir so we can develop and run escripts
             we do not use this ./bin bind or any binds on the production server.
 3. network: network is external, so we make sure is is there before we start
 3. ports: 
   - openresty  accepts request on ports 80 443. All port 80 request are redirected to port 443
   - xqerl accepts requests on port 8081. All request traffic to xqerl comes from openresty.
     In most cases openresty will behave as a reverse proxy for xqerl

On the production host fire-walled internet ingress is **only** via ports 80 443.
The only other port we have open is the SSH port.



# STEPS

## bring containers up

```
make up
```

## preview what we are doing, by altering hosts file

Under the site directory we create directories for the **domains** under our control.


```
.
└── site
    ├── gmack.nz
    │   ├── modules
    │   │   ├── routes.xqm
    │   ├── resources
    │   │   ├── icons
    │   │   │   └── article.svg
    │   │   └── styles
    │   │       └── main.css
```


## **xqerl-compiled-code** volume 

To compile our xQuery modules to run on our locally running `xq`container, 
we pop into our working site based on our `${domain}` ( set in .env ).
then run `make`

```
source .env
pushd site/${DOMAIN}
make
popd
```

Running make will populate the **xqerl-compiled-code** volume


## adding certs to local development *letsencrypt volume*

We are going to replicate the production *letsencrypt volume*.
To do this we `tar` certs from remote production site and 
install on our local development *letsencypt volume*.

```
pushd proxy
make certsToHost
popd
```


## nginx configuration

The nginx configuration file reside in a volume named **nginx-conguration** 

The directory *nginx configuration* file is conf
The build process just copies file from the *conf* directory into the `./.build/nginx/conf` directory
Once the build files are in place the build process will copy the files into the **nginx-configuration** volume

```
pushd proxy
make
popd
```

There is also a watch target which can be run in a terminal

```
pushd proxy
make watch-confs
popd
```

This uploads a changed file into the *nginx-configuration* volume,
then tests the configuration and reloads nginx. 

## static assets pipeline

```
source .env
pushd site/${DOMAIN}
make assets-build
popd

TODO!






-->
 








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

