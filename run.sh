#!/bin/sh

LATEST_VERSION=$(curl --silent "https://api.github.com/repos/kovidgoyal/calibre/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/' | sed -e 's/^v//g' ) 
LOCAL_VERSION=$(grep -m1 version /opt/calibre/resources/changelog.json 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/' | sed -e 's/^v//g'); [[ -z ${LOCAL_VERSION} ]] && LOCAL_VERSION=NONE 

# install/update calibre converter
echo "[INFO] Latest  version of Calibre converter is \"${LATEST_VERSION}\""
echo "[INFO] Current version of Calibre converter is \"${LOCAL_VERSION}\""
if [ "${LATEST_VERSION}" != "${LOCAL_VERSION}" ]; then
    echo "[INFO] Running install/update of the Calibre (version ${LATEST_VERSION}) ..."
    mkdir -p /opt/calibre && curl -s https://download.calibre-ebook.com/${LATEST_VERSION}/calibre-${LATEST_VERSION}-x86_64.txz | tar xfJ - -C /opt/calibre
fi

# download the latest version of the specified application
echo "[INFO] Checkout the latest $APP_NAME version ..."
if [ ! -d ${APP_HOME}/app/.git ]; then
    export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
    # clone the repository
    echo "[INFO] ... git clone -b ${APP_BRANCH} --single-branch ${APP_REPO} ${APP_HOME}/app -v"
    git clone -b ${APP_BRANCH} --single-branch ${APP_REPO} ${APP_HOME}/app -v
fi

# opt out for autoupdates using env variable
if [ -z "${DISABLE_AUTOUPDATE}" ]; then
    echo "[INFO] Autoupdate is active, try to pull the latest sources for ${APP_NAME} ..."
    cd ${APP_HOME}/app
    echo "[INFO] ... current git status is"
    git status && git rev-parse ${APP_BRANCH}
    echo "[INFO] ... pulling sources"
    git pull
    echo "[INFO] ... git status after update is"
    git status && git rev-parse ${APP_BRANCH}
fi

export LD_LIBRARY_PATH="/lib:/usr/lib:/usr/glibc-compat/lib:/opt/calibre/lib:${LD_LIBRARY_PATH}" 
export PATH="$PATH:/opt/calibre" 
export LC_ALL="C" 

# create initial calibre db if not exist
if [ ! -f ${CALIBRE_PATH}/metadata.db ]; then 
    echo "[INFO] Creating empty Calibre database in the \"${CALIBRE_PATH}\" directory ..."
    /opt/calibre/calibredb restore_database --really-do-it --with-library ${CALIBRE_PATH}
fi

# create initial settings if not exist
if [ ! -f ${CALIBRE_DBPATH}/app.db ]; then 
    echo "[INFO] Creating initial Calibre settings file \"${CALIBRE_DBPATH}/app.db\" ..."
    /usr/bin/python3 "${APP_HOME}/app/cps.py" $* & export INITPID=$!
    sleep 15; kill -9 $INITPID; sleep 5
fi

# set calibre db location if not set
if [ -z $(sqlite3 ${CALIBRE_DBPATH}/app.db "SELECT config_calibre_dir FROM settings WHERE id = 1;") ]; then
    echo "[INFO] Set location of the Calibre database to \"${CALIBRE_PATH}\" directory ..."
    sqlite3 ${CALIBRE_DBPATH}/app.db "UPDATE settings SET config_calibre_dir = \"${CALIBRE_PATH}\", config_uploading = '1' WHERE id = 1;"
fi

echo "[INFO] Running calibre_web server ..."
exec /usr/bin/python3 "${APP_HOME}/app/cps.py"
