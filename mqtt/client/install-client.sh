#!/bin/sh

LOCALDIR="/var/etc/persistent/mqtt"
LOCALSCRIPTDIR=$LOCALDIR/client
BASEURL="https://raw.githubusercontent.com/mmv-ru/mFi-tools/master/mqtt"
INSTALLTMPDIR="/tmp/mfi-tools-install/$$"

installfrominet() {
        wget --no-check-certificate $BASEURL/$1?raw=true -O $INSTALLTMPDIR/$1 && mv $INSTALLTMPDIR/$1 $LOCALDIR/$1
}

echo "Installing mFi tools MQTT v3.2 ..."
mkdir -p $LOCALDIR
mkdir -p $INSTALLTMPDIR
installfrominet libmosquitto.so.1
installfrominet mosquitto_pub
installfrominet mosquitto_sub
mkdir -p $LOCALSCRIPTDIR
mkdir -p $INSTALLTMPDIR/client
# clean directory, but leave *.cfg files untouched
#find $LOCALSCRIPTDIR ! -name '*.cfg' -type f -exec rm -f '{}' \;
installfrominet client/mqrun.sh
installfrominet client/mqpub-static.sh
installfrominet client/mqpub.sh
installfrominet client/mqsub.sh
installfrominet client/mqstop.sh

installfrominet client/model.sample.cfg
if [ ! -f $LOCALSCRIPTDIR/model.cfg ]; then
    cp $LOCALSCRIPTDIR/model.sample.cfg $LOCALSCRIPTDIR/model.cfg
fi

installfrominet client/mpower-pub.sample.cfg
if [ ! -f $LOCALSCRIPTDIR/mpower-pub.cfg ]; then
    cp $LOCALSCRIPTDIR/mpower-pub.sample.cfg $LOCALSCRIPTDIR/mpower-pub.cfg
fi

installfrominet client/mqtt.sample.cfg
if [ ! -f $LOCALSCRIPTDIR/mqtt.cfg ]; then
    cp $LOCALSCRIPTDIR/mqtt.sample.cfg $LOCALSCRIPTDIR/mqtt.cfg
fi


echo Set permissions
chmod 755 $LOCALDIR/mosquitto_pub
chmod 755 $LOCALDIR/mosquitto_sub
chmod 755 $LOCALSCRIPTDIR/mqrun.sh
chmod 755 $LOCALSCRIPTDIR/mqpub-static.sh
chmod 755 $LOCALSCRIPTDIR/mqpub.sh
chmod 755 $LOCALSCRIPTDIR/mqsub.sh
chmod 755 $LOCALSCRIPTDIR/mqstop.sh



echo Configure start after reboot
poststart=/etc/persistent/rc.poststart
startscript=$LOCALSCRIPTDIR/mqrun.sh
 
if [ ! -f $poststart ]; then
    echo "$poststart not found, creating it ..."
    touch $poststart
    echo "#!/bin/sh" >> $poststart
    chmod 755 $poststart
fi
 
if grep -q "$startscript" "$poststart"; then
   echo "Found $poststart entry. File will not be changed"
else
   echo "Adding start command to $poststart"
   echo "$startscript" >> $poststart
fi

rm -rf "$INSTALLTMPDIR"

echo "Done!"
echo "Please configure mqtt.cfg"
echo "Please configure mpower-pub.cfg"
echo "run 'save' command if done."
