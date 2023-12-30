#!/bin/sh

log() {
        logger -s -t "mqtt" "$*"
}

export LD_LIBRARY_PATH=/var/etc/persistent/mqtt
export BIN_PATH=/etc/persistent/mqtt
export devicename=$(cat /tmp/system.cfg | grep resolv.host.1.name | sed 's/.*=\(.*\)/\1/')
export HWID=`cat /etc/board.inc | grep board_hwaddr | sed -e 's/.*="\(.*\)";/\1/'`
export BOARD_NAME=`cat /etc/board.inc | grep board_name | sed -e 's/.*="\(.*\)";/\1/'`
export BOARD_RAW_NAME=`cat /etc/board.inc | grep board_raw_name | sed -e 's/.*="\(.*\)";/\1/'`
export BOARD_ID=`cat /etc/board.inc | grep board_id | sed -e 's/.*="\(.*\)";/\1/'`
export BOARD_REVISION=`cat /etc/board.inc | grep board_revision | sed -e 's/.*="\(.*\)";/\1/'`
# MQTT ClientID must be uniqie for MQTT server
export clientID=${BOARD_NAME}_$HWID
# preferable not change topic on every minor change of $devicename
export topic=homie/${BOARD_NAME}-$HWID

log "devicename: $devicename"
log "board_hwaddr: $HWID"
log "BOARD_NAME: $BOARD_NAME"
log "BOARD_RAW_NAME: $BOARD_RAW_NAME"
log "BOARD_ID: $BOARD_ID"
log "BOARD_REVISION: $BOARD_REVISION"
log "clientID: $clientID"
log "topic: $topic"

refresh=60
SLOWUPDATENUMBER=6
version=$(cat /etc/version)-mq-0.2

# Load config
source $BIN_PATH/client/mqtt.cfg

if [ -z "$mqtthost" ]; then
    echo "no host specified"
    exit 0
fi

if [ -z "$mqttusername" ] || [ -z "$mqttpassword" ]; then
    export auth=""
else
    export auth="-u $mqttusername -P $mqttpassword"
fi

# lets stop any process from former start attempts
$BIN_PATH/client/mqstop.sh

# make sure the MQTT fast update request file exists
rm /tmp/mqtmp.*
tmpfile=$(mktemp /tmp/mqtmp.XXXXXXXXXX)
log "Using temp file "$tmpfile
echo 0 > $tmpfile

# make our settings available to the subscripts
export mqtthost
export refresh
export tmpfile
export version
export port1
export port2
export port3
export SLOWUPDATENUMBER
export MQTTPARAMS="-h $mqtthost $auth -q 1"
export LWT="--will-topic $topic/\$state --will-payload lost --will-qos 1"

log "starting pub and sub scripts"
$BIN_PATH/client/mqpub.sh &
$BIN_PATH/client/mqsub.sh &
