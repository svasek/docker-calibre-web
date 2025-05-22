FROM alpine:3.21

ARG IMAGE_VERSION=1.16 \
    GLIBC_VERSION=2.35-r1

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
    # Workaround for incompatible Calibre 6.x
    # Set CALIBRE_VERSION=0 to use latest version
    CALIBRE_VERSION="5.44.0" \
    # This hack is widely applied to avoid python printing issues in docker containers.
    # See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
    PYTHONUNBUFFERED=1 \
    # Set the default locale
    LC_ALL="C" \
    # Set the $LD_LIBRARY_PATH to use glibc libraries
    LD_LIBRARY_PATH="/lib:/usr/lib:/usr/glibc-compat/lib:/opt/calibre/lib" \
    # Python packages
    PKGS_PYTHON_0="py3-wheel py3-wheel-pyc py3-openssl py3-openssl-pyc py3-libxml2 py3-libxml2-pyc py3-setuptools py3-setuptools-pyc" \
    PKGS_PYTHON_1="py3-babel py3-babel-pyc py3-flask-babel py3-flask-babel-pyc py3-flask py3-flask-pyc py3-tz py3-tz-pyc \
    py3-requests py3-requests-pyc py3-sqlalchemy py3-sqlalchemy-pyc py3-apscheduler py3-apscheduler-pyc py3-tornado py3-tornado-pyc \
    py3-unidecode py3-unidecode-pyc py3-lxml py3-lxml-pyc py3-flask-wtf py3-flask-wtf-pyc py3-chardet py3-chardet-pyc \
    py3-regex py3-regex-pyc py3-iso639 py3-iso639-pyc py3-flask-principal py3-flask-principal-pyc py3-wand py3-wand-pyc \
    py3-bleach py3-bleach-pyc py3-magic py3-magic-pyc py3-urllib3 py3-urllib3-pyc py3-cryptography py3-cryptography-pyc py3-netifaces \
    py3-rarfile py3-rarfile-pyc py3-natsort py3-natsort-pyc py3-dateutil py3-dateutil-pyc py3-beautifulsoup4 py3-beautifulsoup4-pyc \
    py3-html2text py3-html2text-pyc py3-mutagen py3-mutagen-pyc py3-pycountry" \
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
    # added repository Alpine:3.14 for unrar which is missing in newer Alpine
    echo "**** install Packages ****" && \
    apk -U add --no-cache --repository https://dl-cdn.alpinelinux.org/alpine/v3.14/main \
        tzdata git curl python3 ca-certificates libxml2 libxslt libev unrar sqlite \
        fontconfig freetype lcms2 libjpeg-turbo libltdl libpng libwebp tiff \
        zlib ghostscript mesa-gl mesa-egl libxkbcommon imagemagick imagemagick-libs \
        ${PKGS_DEVEL} ${PKGS_PYTHON_0} ${PKGS_PYTHON_1} && \
    \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk && \
    apk add --no-cache --force-overwrite glibc-${GLIBC_VERSION}.apk && rm -f glibc-${GLIBC_VERSION}.apk && \
    mkdir /lib64 && ln -sf /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 && \
    \
    echo "---- Install python packages via pip ----" && \
    ### REQUIRED ###
    ### see https://github.com/janeczku/calibre-web/blob/master/requirements.txt
    ### optional: https://github.com/janeczku/calibre-web/blob/master/optional-requirements.txt
    ### Most of them are replaced by a system packages
    pip install --no-cache-dir --upgrade --break-system-packages \
        'PyPDF>=3.15.6,<5.1.0' \
        #'advocate>=1.0.0,<1.1.0' \
        'netifaces-plus>=0.12.0,<0.13.0' \
        'Flask-Limiter>=2.3.0,<3.9.0' \
        #'bleach>=6.0.0,<6.2.0' \
        'flask-httpAuth>=4.4.0,<5.0.0' \
        ## OPTIONAL
        # Comics
        'comicapi>=2.2.0,<2.3.0' \
        # metadata extraction
        'scholarly>=1.2.0,<1.8' \
        'markdown2>=2.0.0,<2.5.0' \
        'faust-cchardet>=2.1.18,<2.1.20' \
        'py7zr>=0.15.0,<0.21.0' \
    && \
    # fix imagemagick pdf rule
    sed -i 's#<!-- <policy domain="module" rights="none" pattern="{PS,PDF,XPS}" /> -->#<policy domain="module" rights="read" pattern="PDF" />#g' \
        /etc/ImageMagick-*/policy.xml && \
    # fix issue of 'fake_useragent' with module not connecting properly - IndexError
    sed -i 's/table class="w3-table-all notranslate/table class="ws-table-all notranslate/g' \
        /usr/lib/python3.12/site-packages/fake_useragent/utils.py && \
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
    git config --global pull.rebase false && git config --global --add safe.directory ${APP_HOME}/app 

USER calibre 

# set the working directory for the APP
WORKDIR ${APP_HOME}/app

COPY run.sh ${APP_HOME}/run.sh 

# Set volumes for the Calibre Web folder structure
VOLUME ${CALIBRE_DBPATH} ${CALIBRE_PATH}

# Expose ports
EXPOSE ${CALIBRE_PORT}

CMD ${APP_HOME}/run.sh 
