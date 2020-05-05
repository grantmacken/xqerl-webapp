

This directory contains the nginx reverse proxy server configuration files
for running a reverse proxy for xqerl.

Running `make` should create deployable artifact in the form of a *nginx-configuration-volume* tar located in the ../deploy directory.

You should be able to run `make` locally and via 'github actions'.

Each time make is ran, prior to being uploaded,
the nginx configuration will be tested.


Live Preview: After the build is completed,
 if make is not ran via github actions, 
 then `xdotool` is invoked to reload the active firefox browser tab.

## other targets

`make watch` target: When activated watches this directory for file changes and 
runs make whenever a file is changed.

`make up` target: 

`make down` target: 

`make info` target:  show show ngnix installation details









