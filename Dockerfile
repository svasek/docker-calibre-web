FROM alpine:3.15
ARG VERSION=1.2

LABEL maintainer="Milos Svasek <Milos@Svasek.net>" \
      image.version="${VERSION}" \
      image.description="Docker image for Calibre Web, based on Alpine" \
      url.docker="https://hub.docker.com/r/svasek/calibre-web" \
      url.github="https://github.com/svasek/docker-calibre-web"

# Set basic environment settings
ENV \
    # - VERSION: the docker image version (corresponds to the above LABEL image.version)
    VERSION="${VERSION}" \
    \
    # - APP_NAME: the APP name
    APP_NAME="Calibre-Web" \
    \
    # - APP_HOME: the APP home directory
    APP_HOME="/calibre-web" \
    \
    # - APP_REPO, APP_BRANCH: the APP GitHub repository and related branch
    # for related branch or tag use e.g. master
    APP_REPO="https://github.com/janeczku/calibre-web.git" \
    APP_BRANCH="master" \
    \
    # - CALIBRE_PATH: Configure the path where the Calibre database is located
    CALIBRE_PATH="/books" \
    CALIBRE_DBPATH="/calibre-web/config" \
    CALIBRE_PORT="8083" \
    \
    # This hack is widely applied to avoid python printing issues in docker containers.
    # See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
    PYTHONUNBUFFERED=1 

RUN \
    # create temporary directories
    mkdir -p /tmp && \
    \
    # upgrade installed packages
    apk -U upgrade && \
    \
    # install python and create a symlink as python
    # added repository Alpine:3.14 for unrar which is missing in 3.15
    echo "**** install Packages ****" && \
    apk -U add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/v3.14/main \
        tzdata git curl python3 ca-certificates libxml2 libxslt libev unrar sqlite \
        py3-pip py3-wheel py3-openssl py3-setuptools py3-libxml2 py3-chardet \
        py3-lxml py3-babel py3-flask-babel py3-flask-login py3-flask py3-flask-wtf py3-natsort\
        py3-rarfile py3-tz py3-requests py3-sqlalchemy py3-tornado py3-unidecode \ 
        fontconfig freetype lcms2 libjpeg-turbo libltdl libpng libwebp tiff \
        zlib ghostscript mesa-gl imagemagick6 imagemagick6-libs && \
    \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.34-r0/glibc-2.34-r0.apk && \
    apk add --no-cache --allow-untrusted glibc-2.34-r0.apk && rm -f glibc-2.34-r0.apk && \
    \
    echo "---- Install python packages via pip ----" && \
    ### REQUIRED ###
    ### see https://github.com/janeczku/calibre-web/blob/master/requirements.txt
    ### Most of them are replaced by a system packages
    pip install --no-cache --upgrade \
        'Flask-Principal>=0.3.2,<0.5.1' \
        'singledispatch>=3.4.0.0,<3.5.0.0' \
        'backports_abc>=0.4' \
        'iso-639>=0.4.5,<0.5.0' \
        'Wand>=0.4.4,<0.7.0' \
        'PyPDF3>=1.0.0,<1.0.6' \
        'comicapi>=2.2.0,<2.3.0' \
        'scholarly>=1.2.0,<1.5' \
    && \
    # fix issue of 'fake_useragent' with module not connecting properly - IndexError
    sed -i 's/table class="w5-table-all notranslate/table class="ws-table-all notranslate/g' \
        /usr/lib/python3.9/site-packages/fake_useragent/utils.py && \
    # cleanup temporary files
    rm -rf /tmp/* && \
    rm -rf /var/cache/apk/* && \
    \
    # create Calibre Web folder structure
    mkdir -p $APP_HOME/app && \
    mkdir -p $APP_HOME/config && \
    # set defaults
    git config --global pull.rebase false

# set the working directory for the APP
WORKDIR $APP_HOME/app

COPY run.sh $APP_HOME/run.sh 

# Set volumes for the Calibre Web folder structure
VOLUME /books
VOLUME $APP_HOME/app
VOLUME $APP_HOME/config

# Expose ports
EXPOSE $CALIBRE_PORT

CMD $APP_HOME/run.sh 
