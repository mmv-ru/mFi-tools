#!/bin/sh

model_lookup() {
    awk -F ";" "/$1/ { print \$$2 }" $BIN_PATH/client/model.cfg
}

# homie spec (incomplete)
$PUBBIN $MQTTPARAMS -t $topic/\$homie -m "3.0.0" -r
$PUBBIN $MQTTPARAMS -t $topic/\$name -m "$devicename" -r
$PUBBIN $MQTTPARAMS -t $topic/\$fw/version -m "$version" -r

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
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$name -m "$(model_lookup $portrole 3)" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$settable -m "false" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$unit -m "$(model_lookup $portrole 4)" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$datatype -m "$(model_lookup $portrole 5)" -r
            $PUBBIN $MQTTPARAMS -t $topic/port$i/$(model_lookup $portrole 2)/\$format -m "$(model_lookup $portrole 6)" -r
        fi
    done

fi

if [ "$mFiType" == "mPower" ] || [ "$mFiType" == "mPower Mini" ] || [ "$mFiType" == "mPower Pro" ]
then
    properties=relay

    if [ $energy -eq 1 ]
    then
        properties=$properties,energy
    fi

    if [ $power -eq 1 ]
    then
        properties=$properties,power
    fi

    if [ $voltage -eq 1 ]
    then
        properties=$properties,voltage
    fi

    if [ $current -eq 1 ]
    then
        properties=$properties,current
    fi

    if [ $lock -eq 1 ]
    then
        properties=$properties,lock
    fi

    # node infos
    for i in $(seq $PORTS)
    do
        $PUBBIN $MQTTPARAMS -t $topic/port$i/\$name -m "Port $i" -r
        $PUBBIN $MQTTPARAMS -t $topic/port$i/\$type -m "power switch" -r
        $PUBBIN $MQTTPARAMS -t $topic/port$i/\$properties -m "$properties" -r
        $PUBBIN $MQTTPARAMS -t $topic/port$i/relay/\$settable -m "true" -r
        if [ $energy -eq 1 ]
        then
            property=energy
            property_base=$topic/port$i/$property
            # required property attributes
            $PUBBIN $MQTTPARAMS -t $property_base/\$name -m "s$i $property" -r
            $PUBBIN $MQTTPARAMS -t $property_base/\$datatype -m "float" -r
            # optional property attributes
            $PUBBIN $MQTTPARAMS -t $property_base/\$datatype -m "float" -r
        fi

        if [ $power -eq 1 ]
        then
            $PUBBIN $MQTTPARAMS -t $topic/port$i/power/\$name -m "s$i power" -r
        fi

        if [ $voltage -eq 1 ]
        then
            $PUBBIN $MQTTPARAMS -t $topic/port$i/voltage/\$name -m "s$i voltage" -r
        fi

        if [ $current -eq 1 ]
        then
            $PUBBIN $MQTTPARAMS -t $topic/port$i/current/\$name -m "s$i current" -r
        fi

        if [ $lock -eq 1 ]
        then
            $PUBBIN $MQTTPARAMS -t $topic/port$i/lock/\$settable -m "true" -r
        fi
    done


fi

$PUBBIN $MQTTPARAMS -t $topic/\$state -m "ready" -r
