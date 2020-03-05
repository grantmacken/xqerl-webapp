# xqerl-webapp
maybe a template for a xQuery webapp projects using xqerl, but just now an experiment


#WIP!

All text a work in progress. Be warned I make lots of typos



## Containers And Container Volumes

1. nginx as a *cache*, *proxy*, and *static file* server
2. xqerl resides behind our nginx proxy as an web application server

xqerl provides capabilities to handle structured marked up data resources like HTML, XML, JSON and CSV
 - a restXQ implementation providing an API interface to Create Retrieve Update Delete these resources in its internal data store.
 - a HTTP client giving the ability to retrieve external and internal network resources 
 - an xQuery application engine to retrieve, query and transform data resources via the *functional*, *typed* **xQuery** language

Since containers are ephemeral by nature, 
we provide docker volumes to persist data between stopping and starting the containers.

 - **letsencrypt**
 - **nginx-configuration** 
 - **static-assets** 
 - **xqerl-compiled-code**
 - **xqerl-database**


Our `Make` build artifacts are tar archives produced from container volumes.
These tars end up in the deploy directory. 
To **deploy** these tar archives they are simply untared into their respective volumes. 
This is done using running short lived containers, and not via a running `ps` container.

## Local Actions

Under the site directory we create directories 
for the **domains** under our control and have 
two main working directories

```
.
└── site
    └── gmack.nz
        ├── modules
        └── resources
```

 1. modules:   this contains the xQuery modules to be compiled by xqerl to run on the [beam](https://en.wikipedia.org/wiki/BEAM_(Erlang_virtual_machine))
 2. resources: this contains the static assets for the site with each asset class 
 having its own directory and a **build pipeline** to the build directiory


### On xQuery 3.1

xQuery is both ***data query language*** and a ***typed functional programing language*** ideal for building data driven
websites asn web applications.

#### Data Query Language

With xQuery 3.1 query data sources for have expanded beyond XML to incorporating JSON 
and other structured data formats like CSV. It also has the capacity to deal with 
extracting data unparsed text through [regular expressions](https://www.regular-expressions.info/xpath.html)

Whats more query output [serialisation](https://www.w3.org/TR/xslt-xquery-serialization-31) is expanded to include
JSON, HTML, Text and an 'adaptive output method'

#### Typed Functional Programing Language

With xQuery has always been a **typed functional programing language**, however with xQuery 3.1 there have been several improvements.

1. has new syntax coding sugar which makes functional code more **readable**, like the 'new arrow' and 'bang' operators.
2. introduces new string contructors which allows for easy string interpolation like traditional 'here docs' or logic-less 'mustache' like templating
3. extends the [XQuery and xPath](https://www.w3.org/TR/xpath-datamodel) **data model** to include functions, maps array that make serialising to and from JSON easier.
4. introduces basic higher order functions: for-each fold-left, fold-right, sort, apply as well as function introspection with function-lookup.

All in all xQuery 3.1  is a well thought out powerful ***data query language** and ***typed functional programming*** language 

#### xQuery 3.1 on the beam.

xqerl is a erlang application 

TODO!


## xqerl development environment

In project root, bring docker containers up.


```
make up
```

NOTE: if you have not setup the nginx proxy and obtained your certs for your domains, 
the proxy will start serving on port 80 and port 443, but will not yet act as a reverse proxy for xqerl. 
xqerl will be serving on port 8081, and we can start creating our xQuery modules

### A main restXQ module as an entry-point to serving resources from a site domain.
```
.
└── site
    ├── gmack.nz
    │   ├── modules
    │   │   ├── routes.xqm

```

TODO!


###  build pipelines for static assets

Our build pipelines consists of chaining together io from short lived container instances.

Example: for a css resource:
 - we use css nano to reduces file size,
 - then use zopfli to gzip.

This build pipelining is driven by Make. 
e.g. `make styles` the corresponding  *Makefile* section

 ```
$(T)/$(DOMAIN)/resources/styles/%.css: resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@echo  ' - use cssnano to reduce css file size'
	@cat $< | docker run \
  --rm \
  --init \
  --name cssnano \
  --interactive \
   docker.pkg.github.com/grantmacken/alpine-cssnano/cssnano:0.0.3 > $@

$(B)/$(DOMAIN)/resources/styles/%.css.gz: $(T)/$(DOMAIN)/resources/styles/%.css
	@echo "##[ $(notdir $@) ]##"
	@echo  ' - use zopfli to gzip file'
	@cat $< | docker run \
  --rm \
  --name zopfli \
  --interactive \
  docker.pkg.github.com/grantmacken/alpine-zopfli/zopfli:0.0.1 > $@
	@echo "orginal size: [ $$(wc -c $< | cut -d' ' -f1) ]"
	@echo "cssnano size: [ $$(wc -c $(T)/$(DOMAIN)/resources/styles/$*.css | cut -d' ' -f1) ]"
	@echo "   gzip size: [ $$(wc -c  $@ | cut -d' ' -f1) ]"
```

The resulting build files will have a `.gz` extension
These are directly served by our server nginx using the `http_gzip_static_module`

All the stuff under the resources director can be built by the make target 'assets'

```
make assets
```
Once built, the built assets are copied into the `static-assets` volume using a short lived container instance. This 'static-assets' volume is then tared, so the actual  *build artifact* from `make assets` that can be deployed is a tar file named `static-assets.tar`. It is found in the deploy directory at project root.

<!--
However before we deploy, we should run some *local* tests on a running container instance.

## Github Actions

1. build phases => produce tar archives => untar into container volumes
 - TODO
2. running container test phases
  - xqerl container tests:
    - bring xqerl container up
    - use xqerl container internal IPAddress and published port to test restXQ routes
  - proxy container tests:
    - add domain under test to /etc/hosts
    - curl tests using domain to check behaviour of proxy
3. google cloud deploy phase
  - move tars into GCE host
  - untar tars into respective volumes
  - compile xqerl code
  - reload proxy





-->











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

