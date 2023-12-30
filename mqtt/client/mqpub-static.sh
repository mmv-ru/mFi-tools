#!/bin/sh

model_lookup() {
    awk -F ";" "/^$1;/ { print \$$2 }" $BIN_PATH/client/model.cfg
}

log() {
        logger -s -t "mqtt" "$*"
}

# homie spec (incomplete)
$PUBBIN $MQTTPARAMS -t $topic/\$homie -m "4.0.0" -r
$PUBBIN $MQTTPARAMS -t $topic/\$name -m "$devicename" -r
$PUBBIN $MQTTPARAMS -t $topic/\$fw/version -m "$version" -r
# $extensions required for homie 4.0.0

$PUBBIN $MQTTPARAMS -t $topic/\$extensions -n -r
# $implementation is optional
$PUBBIN $MQTTPARAMS -t $topic/\$implementation -m "mFi MQTT" -r

# identify mFi device
export mFiType=`cat /etc/board.inc | grep board_name | sed -e 's/.*="\(.*\)";/\1/'`

$PUBBIN $MQTTPARAMS -t $topic/\$fw/name -m "mFi MQTT" -r

for IFNAME in ath0 eth0 eth1 wifi0
do
    IPADDR=`ifconfig $IFNAME | grep 'inet addr' | cut -d ':' -f 2 | awk '{ print $1 }'`
    if [ "$IPADDR" != "" ]; then break; fi
done
$PUBBIN $MQTTPARAMS -t $topic/\$localip -m "$IPADDR" -r

MACADDR=`ifconfig $IFNAME | grep 'HWaddr' | awk '{print $NF}'`
$PUBBIN -h $mqtthost -t $topic/\$mac -m "$MACADDR" -r


NODES=`seq $PORTS | sed 's/\([0-9]\)/port\1/' |  tr '\n' , | sed 's/.$//'`
$PUBBIN $MQTTPARAMS -t $topic/\$nodes -m "$NODES" -r

UPTIME=`awk '{print $1}' /proc/uptime`
$PUBBIN $MQTTPARAMS -t $topic/\$stats/uptime -m "$UPTIME" -r


if [ "$mFiType" != "mPower" ] && [ "$mFiType" != "mPower Mini" ] && [ "$mFiType" != "mPower Pro" ]
then
    # node infos
    for i in $(seq $PORTS)
    do
        portname="port$i"
        eval portrole="\$$portname"
        if [ "$portrole" != "" ] ; then
            $PUBBIN $MQTTPARAMS -t $topic/port$i/\$name -m "Port $i ($portrole)" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/\$type -m "$portrole" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/\$properties -m "$(model_lookup $portrole 2)" -r
            # required property's attributes
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$name -m "$(model_lookup $portrole 3)" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$datatype -m "$(model_lookup $portrole 5)" -r
            # optional property's attributes
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$settable -m "false" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$unit -m "$(model_lookup $portrole 4)" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$format -m "$(model_lookup $portrole 6)" -r
        fi
    done

fi

if [ "$mFiType" == "mPower" ] || [ "$mFiType" == "mPower Mini" ] || [ "$mFiType" == "mPower Pro" ]
then
    properties=""
    enabled_properties=""
    for prop in $socket_properties
    do
        eval prop_enabled=\$$prop
        if [ $prop_enabled -eq 1 ]
        then
            if [ "%$properties%" == "%%" ] ; then
                properties="$prop"
                enabled_properties="$prop"
            else
                properties="$properties,$prop"
                enabled_properties="$enabled_properties $prop"
            fi
        fi
    done

    # node infos
    for i in $(seq $PORTS)
    do
        $PUBBIN $MQTTPARAMS -t $topic/port$i/\$name -m "Socket $i" -r
        $PUBBIN $MQTTPARAMS -t $topic/port$i/\$type -m "Smart power socket" -r
        $PUBBIN $MQTTPARAMS -t $topic/port$i/\$properties -m "$properties" -r

        for prop in $enabled_properties
        do
            # required property's attributes
            prop_name="$(model_lookup $prop 3)"
            eval 'prop_name="$prop_name"'
            log "$prop name: $prop_name"
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$prop/\$name -m "$(eval echo \"$(model_lookup $prop 3)\" )" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$prop/\$datatype -m "$(model_lookup $prop 5)" -r
            # optional property's attributes
            prop_unit="$(model_lookup $prop 4)"
            if [ "-$prop_unit-" != "--" ]; then
                $PUBBIN $MQTTPARAMS -t $topic/port$i/$prop/\$unit -m "$prop_unit" -r
            fi

            prop_format="$(model_lookup $prop 6)"
            if [ "-$prop_format-" == "--" ]; then
                $PUBBIN $MQTTPARAMS -t $topic/port$i/$prop/\$format -m "$prop_format" -r
            fi

            if [ "$prop" == "relay" ] || [ "$prop" == "lock" ]; then
                $PUBBIN $MQTTPARAMS -t $topic/port$i/$prop/\$settable -m "true" -r
            else
                # for Homie 4 $settable=false is default and can be ommited
                $PUBBIN $MQTTPARAMS -t $topic/port$i/$prop/\$settable -m "false" -r
            fi

        done
    done


fi

$PUBBIN $MQTTPARAMS -t $topic/\$state -m "ready" -r
