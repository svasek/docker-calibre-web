FROM alpine:3.15

ARG IMAGE_VERSION=1.9 \
    GLIBC_VERSION=2.35-r0

LABEL maintainer="Milos Svasek <Milos@Svasek.net>" \
      image.version="${IMAGE_VERSION}" \
      image.description="Docker image for Calibre Web, based on Alpine" \
      url.docker="https://hub.docker.com/r/svasek/calibre-web" \
      url.github="https://github.com/svasek/docker-calibre-web"

# Set basic environment settings
ENV \
    # - IMAGE_VERSION: the docker image version (corresponds to the above LABEL image.version)
    IMAGE_VERSION="${IMAGE_VERSION}" \
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
    PYTHONUNBUFFERED=1 \
    # Set the default locale
    LC_ALL="C" \
    # Set the $LD_LIBRARY_PATH to use glibc libraries
    LD_LIBRARY_PATH="/lib:/usr/lib:/usr/glibc-compat/lib:/opt/calibre/lib" \
    # Python packages
    PKGS_PYTHON_0="py3-wheel py3-openssl py3-libxml2 py3-setuptools" \
    PKGS_PYTHON_1="py3-babel py3-flask-babel py3-flask-login py3-flask py3-tz py3-requests py3-sqlalchemy py3-werkzeug \
    py3-tornado py3-unidecode py3-lxml py3-flask-wtf py3-chardet py3-rarfile py3-natsort py3-dateutil py3-beautifulsoup4" \
    # Development packages necessary for instalation/compilation python modules with pip
    PKGS_DEVEL="python3-dev py3-pip gcc g++ musl-dev linux-headers"

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
        fontconfig freetype lcms2 libjpeg-turbo libltdl libpng libwebp tiff \
        zlib ghostscript mesa-gl imagemagick6 imagemagick6-libs \
        ${PKGS_DEVEL} ${PKGS_PYTHON_0} ${PKGS_PYTHON_1} && \
    \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    apk add --no-cache glibc-${GLIBC_VERSION}.apk && rm -f glibc-${GLIBC_VERSION}.apk && \
    mkdir /lib64 && ln -sf /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 && \
    \
    echo "---- Install python packages via pip ----" && \
    ### REQUIRED ###
    ### see https://github.com/janeczku/calibre-web/blob/master/requirements.txt
    ### optional: https://github.com/janeczku/calibre-web/blob/master/optional-requirements.txt
    ### Most of them are replaced by a system packages
    pip install --no-cache-dir --upgrade \
        'APScheduler>=3.6.3,<3.10.0' \
        'Flask-Principal>=0.3.2,<0.5.1' \
        'backports_abc>=0.4' \
        'iso-639>=0.4.5,<0.5.0' \
        'Wand>=0.4.4,<0.7.0' \
        'PyPDF3>=1.0.0,<1.0.7' \
        ## OPTIONAL
        # Comics
        'comicapi>=2.2.0,<2.3.0' \
        # metadata extraction
        'scholarly>=1.2.0,<1.7' \
        'markdown2>=2.0.0,<2.5.0' \
        'html2text>=2020.1.16,<2022.1.1' \
        'cchardet>=2.0.0,<2.2.0' \
        'advocate>=1.0.0,<1.1.0' \
    && \
    # fix imagemagick pdf rule
    sed -i 's#<!-- <policy domain="module" rights="none" pattern="{PS,PDF,XPS}" /> -->#<policy domain="module" rights="read" pattern="PDF" />#g' \
        /etc/ImageMagick-6/policy.xml && \
    # fix issue of 'fake_useragent' with module not connecting properly - IndexError
    sed -i 's/table class="w3-table-all notranslate/table class="ws-table-all notranslate/g' \
        /usr/lib/python3.9/site-packages/fake_useragent/utils.py && \
    # uninstall unnecessary packages
    apk del --purge ${PKGS_DEVEL} && \
    # cleanup temporary files
    rm -rf /tmp/* && rm -rf /var/cache/apk/* && \
    \
    # create runtime user
    adduser --disabled-password --home ${APP_HOME} calibre && \
    # create Calibre Web folder structure
    mkdir -p ${APP_HOME}/app ${CALIBRE_DBPATH} ${CALIBRE_PATH} /opt/calibre && \
    chown calibre:calibre -R ${APP_HOME}/app ${CALIBRE_DBPATH} ${CALIBRE_PATH} /opt/calibre && \
    # set defaults
    git config --global pull.rebase false

USER calibre 

# set the working directory for the APP
WORKDIR ${APP_HOME}/app

COPY run.sh ${APP_HOME}/run.sh 

# Set volumes for the Calibre Web folder structure
VOLUME ${CALIBRE_DBPATH} ${CALIBRE_PATH}

# Expose ports
EXPOSE ${CALIBRE_PORT}

CMD ${APP_HOME}/run.sh 
