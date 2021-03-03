#!/bin/sh

LATEST_VERSION=$(curl --silent "https://api.github.com/repos/kovidgoyal/calibre/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/' | sed -e 's/^v//g' ) 
LOCAL_VERSION=$(grep -m1 version /opt/calibre/resources/changelog.json | sed -E 's/.*"([^"]+)".*/\1/' | sed -e 's/^v//g')

# install/update calibre converter
#if [ -f $APP_HOME/ebook-convert.version ]; then LOCAL_VERSION=$(cat $APP_HOME/ebook-convert.version); fi

echo "[INFO] Latest  version of Calibre converter is \"$LATEST_VERSION\""
echo "[INFO] Current version of Calibre converter is \"$LOCAL_VERSION\""
if [ "$LATEST_VERSION" != "$LOCAL_VERSION" ]; then
    echo "[INFO] ... install/update calibre to /opt"
    mkdir -p /opt/calibre && curl -s https://download.calibre-ebook.com/$LATEST_VERSION/calibre-$LATEST_VERSION-x86_64.txz | tar xfJ - -C /opt/calibre
fi

# download the latest version of the specified application
echo "[INFO] Checkout the latest $APP_NAME version ..."
#cd $APP_HOME/app/
if [ ! -d $APP_HOME/app/.git ]; then
    export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
    # clone the repository
    echo "[INFO] ... git clone -b $APP_BRANCH --single-branch $APP_REPO $APP_HOME/app -v"
    git clone -b $APP_BRANCH --single-branch $APP_REPO $APP_HOME/app -v
fi

# opt out for autoupdates using env variable
if [ -z "$DISABLE_AUTOUPDATE" ]; then
    echo "[INFO] Autoupdate is active, try to pull the latest sources for $APP_NAME ..."
    cd $APP_HOME/app
    echo "[INFO] ... current git status is"
    git status && git rev-parse $APP_BRANCH
    echo "[INFO] ... pulling sources"
    git pull
    echo "[INFO] ... git status after update is"
    git status && git rev-parse $APP_BRANCH
fi

export LD_LIBRARY_PATH="/lib:/usr/lib:/usr/glibc-compat/lib:/opt/calibre/lib:$LD_LIBRARY_PATH" 
export PATH="$PATH:/opt/calibre" 
export LC_ALL="C" 

exec /usr/bin/python3 "$APP_HOME/app/cps.py"
