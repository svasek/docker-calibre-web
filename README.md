# Calibre Web

[![Docker Stars](https://img.shields.io/docker/stars/svasek/calibre-web.svg)]()
[![Docker Pulls](https://img.shields.io/docker/pulls/svasek/calibre-web.svg)]()
[![](https://images.microbadger.com/badges/image/svasek/calibre-web.svg)](https://microbadger.com/images/svasek/calibre-web "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/svasek/calibre-web.svg)](https://microbadger.com/images/svasek/calibre-web "Get your own version badge on microbadger.com")

## Calibre Web - Manage your Calibre e-book collection ##

[Calibre Web](https://github.com/janeczku/calibre-web) is a web app providing a clean interface for browsing, reading and downloading eBooks using an **existing Calibre database**.

![screenshot](https://raw.githubusercontent.com/janeczku/docker-calibre-web/master/screenshot.png)

__Calibre Web__ comes with the following features:

 * Bootstrap 3 HTML5 interface
 * full graphical setup
 * User management
 * Admin interface
 * User Interface in english, french, german, polish, simplified chinese, spanish
 * OPDS feed for eBook reader apps
 * Filter and search by titles, authors, tags, series and language
 * Create custom book collection (shelves)
 * Support for editing eBook metadata
 * Support for converting eBooks from EPUB to Kindle format (mobi/azw)
 * Restrict eBook download to logged-in users
 * Support for public user registration
 * Send eBooks to Kindle devices with the click of a button
 * Support for reading eBooks directly in the browser (.txt, .epub, .pdf)
 * Upload new books in PDF, epub, fb2 format
 * Support for Calibre custom columns
 * Fine grained per-user permissions
 * Self update capability

If you want to know more you can head over to the __Calibre Web__ project site: https://github.com/janeczku/calibre-web.

And if you are interested in the original __Calibre__ ebook management tool then look at the project site: https://calibre-ebook.com/.

## Features ##

 * running Calibre Web 
 * automaticaly updated on every (re)start of the container if needed
 * no usage of NGINX inside the container, only the Calibre Web application is served as single application without any supervisor
 * disabled GoogleDrive/Kobo/GoodReads integrations, ldap, oauth to strip down the image
 * support of **Calibre ebook-convert** tool to convert to MOBI
 * **Calibre ebook-convert** uses `glibc` and therefore https://github.com/sgerrand/alpine-pkg-glibc is installed

## Hints & Tips ##
 
 * if you need SSL support similiar to the original Docker Container [janeczku/calibre-web](https://hub.docker.com/r/janeczku/calibre-web/) then use an additional NGINX or Apache HTTP Server as Reverse-Proxy, e.g see [jwilder/nginx-proxy](https://hub.docker.com/r/jwilder/nginx-proxy/)
 * for Synology Users - don't map a top-level volume directory from the NAS as `/books` volume, e.g. `/volume1/books` because it results into problems with directory permissons. Create instead a subdirectory __calibre__ at `/volume1/books` and map then `/volume1/books/calibre` as volume for `/books`

## Configuration at first launch ##
 1. Point your browser to `http://hostname:<HTTP PORT>` e.g. `http://hostname:8083`
 2. Set Location of your Calibre books folder to the path of the folder where you mounted your Calibre folder in the container, which is by default `/books`.
    So enter at the field __Location of Calibre database__ the mapped volume `/books`.
 3. Hit __Submit__ then __Login__.

Default admin login:
 * __Username:__ admin
 * __Password:__ admin123

After successful login change the default password and set the email adress.

To access the OPDS catalog feed, point your Ebook Reader to `http://hostname:<HTTP PORT>/opds`

## Configuration of a converter ##
   at **Admin** -> **Basic Configuration** -> **E-Book converter** you've to set the converter which you want to use:
   - for the option **Use calibre's ebook converter** set the **Path to convertertool** to `/opt/calibre/ebook-convert`
     and at **About** you will see then `Calibre converter	ebook-convert (calibre 5.9.0)`

## Known issue ##
1. if you map the old/existing app volume like `-v /volume1/docker/apps/calibre-web/app:/calibre-web/app`
   then you'll get the following issue at startup

```
[INFO] Checkout the latest Calibre-Web version ...
[INFO] Autoupdate is active, try to pull the latest sources for Calibre-Web ...
[INFO] ... current git status is
fatal: not a git repository (or any parent up to mount point /calibre-web)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
[INFO] ... pulling sources
fatal: not a git repository (or any parent up to mount point /calibre-web)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
[INFO] ... git status after update is
fatal: not a git repository (or any parent up to mount point /calibre-web)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
```

   To solve the issue delete the old files at `-v /volume1/docker/apps/calibre-web/app:/calibre-web/app`
   before you create and start the container.

## Usage ##

__Create the container:__

```
docker create --name=calibre-web --restart=always \
-v <your Calibre books folder>:/books \
[-v <your Calibre Web application folder>:/calibre-web/app] \
[-v <your Calibre Web config folder>:/calibre-web/config \]
[-e APP_REPO=https://github.com/janeczku/calibre-web.git \]
[-e APP_BRANCH=master \]
-p <HTTP PORT>:8083 \
svasek/calibre-web
```

__Example:__

```
docker create --name=calibre-web --restart=always \
-v /volume1/books/calibre:/books \
-v /etc/localtime:/etc/localtime:ro \
-p 8083:8083 \
svasek/calibre-web
```

or

```
docker create --name=calibre-web --restart=always \
-v /volume1/books/calibre:/books \
-v /volume1/docker/apps/calibre-web/config:/calibre-web/config \
-e TZ=Europe/Vienna \
-p 8083:8083 \
svasek/calibre-web
```

__Start the container:__
```
docker start calibre-web
```

## Parameters ##

### Introduction ###
The parameters are split into two parts which are separated via colon.
The left side describes the host and the right side the container. 
For example a port definition looks like this ```-p external:internal``` and defines the port mapping from internal (the container) to external (the host).
So ```-p 8080:80``` would expose port __80__ from inside the container to be accessible from the host's IP on port __8080__.
Accessing http://'host':8080 (e.g. http://192.168.0.10:8080) would then show you what's running **INSIDE** the container on port __80__.

### Details ###
* `-p 8083` - http port for the web user interface
* `-v /books` - local path which contains the Calibre books and the necessary `metadata.db`  which holds all collected meta-information of the books
* `-v /calibre-web/app` - local path for Calibre Web application files; set this volume if you want to use Google Drive
* `-v /etc/localtime` - for timesync - __optional__
* `-v /calibre-web/config` - local path for Calibre Web config files, like `app.db` and `gdrive.db`
* `-e APP_REPO` - set it to the Calibre Web GitHub repository; by default it uses https://github.com/janeczku/calibre-web.git - __optional__
* `-e APP_BRANCH` - set which Calibre Web GitHub repository branch you want to use, __master__ (default branch) - __optional__

### Container Timezone

In the case of the Synology NAS it is not possible to map `/etc/localtime` for timesync,

Examples:

 * ```UTC``` - __this is the default value if no value is set__
 * ```Europe/Prague```
 * ```Europe/Vienna```
 * ```America/New_York```
 * ...

Once the container is running you can get all possible timezones as tree via the command ```docker exec -it <CONTAINER> tree /usr/share/zoneinfo```

See also at [possible timezone values](TIMEZONES.md).

__Don't use the value__ `localtime` because it results into: `failed to access '/etc/localtime': Too many levels of symbolic links`


## Container Directory Structure ##
```
 /
   |- books
   |- calibre-web
       |- app
       |    |- "all Calibre Web Application files"
       |    |- app.db -> /calibre-web/config/app.db
       |    |- gdrive.db -> /calibre-web/config/gdrive.db
       |    |- calibre-web.log
       |    |- cps 
       |    |    |- *.py
       |    |    |- *.pyc
       |    |
       |    |- vendor
       |         |- kindlegen -> /calibre-web/kindlegen/kindlegen
       |
       |- config
       |    |- app.db
       |    |- gdrive.db
       |
       |- kindlegen
            |- EULA*.txt
            |- KindleGen Legal Notices*.txt
            |- docs
            |- kindlegen
            |- manual.html
```

## Additional ##
Shell access whilst the container is running: `docker exec -it calibre-web /bin/bash`

Upgrade to the latest version of Calibre Web: `docker restart calibre-web`

To monitor the logs of the container in realtime: `docker logs -f calibre-web`

To monitor the logs of Calibre Web: `docker exec -it calibre-web tail -f /calibre-web/app/calibre-web.log`

Show used base image version number of Calibre Web: `docker inspect -f '{{ index .Config.Labels "image.base.version" }}' calibre-web`

Show used image version number of Calibre Web: `docker inspect -f '{{ index .Config.Labels "image.version" }}' calibre-web`

---

## For Synology NAS users ##

Login into the DSM Web Management
* Open the Control Panel
* Control _Panel_ > _Privilege_ > _Group_ and create a new one with the name 'docker'
* add the permissions for the directories 'downloads', 'video' and so on
* disallow the permissons to use the applications
* Control _Panel_ > _Privilege_ > _User_ and create a new on with name 'docker' and assign this user to the group 'docker'

Connect with SSH to your NAS
* after sucessful connection change to the root account via
```
sudo -i
```
or
```
sudo su -
```
for the password use the same one which was used for the SSH authentication.

* create a 'docker' directory on your volume (if such doesn't exist)
```
mkdir -p /volume1/docker/
chown root:root /volume1/docker/
```

* get the Docker image
```
docker pull svasek/calibre-web
```

* create a Docker container (take care regarding the user ID and group ID, change timezone and port as needed)
```
docker create --name=calibre-web --restart=always \
-v /volume1/books/calibre:/books \
-e SET_CONTAINER_TIMEZONE=true \
-e CONTAINER_TIMEZONE=Europe/Vienna \
-e PGID=65539 -e PUID=1029 \
-p 8083:8083 \
svasek/calibre-web
```

* check if the Docker container was created successfully
```
docker ps -a
CONTAINER ID        IMAGE                           COMMAND                CREATED             STATUS              PORTS               NAMES
40cc1bfaf7be        svasek/calibre-web      "/bin/bash -c /init/s" 8 seconds ago       Created 
```

* start the Docker container
```
docker start calibre-web
```
