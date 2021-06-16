#!/bin/sh

log() {
        logger -s -t "mqtt" "$*"
}

# read config file
source $BIN_PATH/client/mpower-pub.cfg
export PUBBIN=$BIN_PATH/mosquitto_pub

# identify mFi device
export mFiType=`cat /etc/board.inc | grep board_name | sed -e 's/.*="\(.*\)";/\1/'`

log "mFi Type: $mFiType."

# identify type of mpower
if [ "$mFiType" == "mPower" ] || [ "$mFiType" == "mPower Mini" ] || [ "$mFiType" == "mPower Pro" ]
then
    export PORTS=`cat /etc/board.inc | grep feature_power | sed -e 's/.*\([0-9]\+\);/\1/'`
else
    # Don't get confused by the 3 ports - mPower also has three ports, but these are not power ports and
    # it's not for mPower
    export PORTS=3
fi

log "Found $((PORTS)) ports."
log "Publishing to $mqtthost with topic $topic"

REFRESHCOUNTER=$refresh
FASTUPDATE=0

SLOWUPDATECOUNTER=0
SLOWUPDATENUMBER=6

export relay=$relay
export power=$power
export energy=$energy
export voltage=$voltage
export current=$current
export lock=$lock
export mFiTHS=$mFiTHS
export mFiCS=$mFiCS
export mFiMSW=$mFiMSW
export mFiMSC=$mFiMSC
export mFiDS=$mFiDS

$BIN_PATH/client/mqpub-static.sh
while sleep 1;
do
    # refresh logic: either we need fast updates, or we count down until it's time
    TMPFASTUPDATE=`cat $tmpfile`
    #echo "TMPFILE = " $TMPFASTUPDATE
    if [ -n "${TMPFASTUPDATE}" ]
        then
                FASTUPDATE=$TMPFASTUPDATE
                : > $tmpfile
        fi

        if [ $FASTUPDATE -ne 0 ]
        then
                # fast update required, we do updates every second until the requested number of fast updates is done
                FASTUPDATE=$((FASTUPDATE-1))
        else
                # normal updates, decrement refresh counter until it is time
                if [ $REFRESHCOUNTER -ne 0 ]
                then
                        # not yet, keep counting
                        REFRESHCOUNTER=$((REFRESHCOUNTER-1))
                        continue
                else
                        # time to update
                        REFRESHCOUNTER=$refresh
                fi
        fi

    if [ "$mFiType" != "mPower" ] && [ "$mFiType" != "mPower Mini" ] && [ "$mFiType" != "mPower Pro" ]
    then

        log "Gathering mPort values."

        # port1
        if [ $mFiTHS -eq 1 ] && [ "$port1" == "mFiTHS" ]
        then
            # temperature
            mFiTHS_val=`cat /proc/analog/value1`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/temperature -m "$mFiTHS_val" -r
        fi
        if [ $mFiCS -eq 1 ]  && [ "$port1" == "mFiCS" ]
        then
            #current
            mFiCS_val=`cat /proc/analog/rms1`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/current -m "$mFiCS_val" -r
        fi
        if [ $mFiMSW -eq 1 ] && [ "$port1" == "mFiMSW" ]
        then
            #sensor movimento
            mFiMSW_val=`cat /dev/input21`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/motion -m "$mFiMSW_val" -r
        fi
        if [ $mFiMSC -eq 1 ] && [ "$port1" == "mFiMSC" ]
        then
            #sensor movimento
            mFiMSC_val=`cat /dev/input21`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/motion -m "$mFiMSC_val" -r
        fi
        if [ $mFiDS -eq 1 ]  && [ "$port1" == "mFiDS" ] || [ "$port2" == "mFiDS" ] || [ "$port3" == "mFiDS" ]
        then
            #sensor abertura porta
            mFiDS_val=`cat /dev/input11`
            $PUBBIN -h $mqtthost $auth -t $topic/port1/door -m "$mFiDS_val" -r
        fi

        # port2
        if [ $mFiTHS -eq 1 ] && [ "$port2" == "mFiTHS" ]
        then
            #temperature
            mFiTHS_val=`cat /proc/analog/value2`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/temperature -m "$mFiTHS_val" -r
        fi
        if [ $mFiCS -eq 1 ] && [ "$port2" == "mFiCS" ]
        then
            #pinca corrente
            mFiCS_val=`cat /proc/analog/rms2`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/current -m "$mFiCS_val" -r
        fi

        if [ $mFiMSW -eq 1 ] && [ "$port2" == "mFiMSW" ]
        then
            #sensor movimento
            mFiMSW_val=`cat /dev/input22`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/motion -m "$mFiMSW_val" -r
        fi

        if [ $mFiMSC -eq 1 ] && [ "$port2" == "mFiMSC" ]
        then
            #sensor movimento
            mFiMSC_val=`cat /dev/input22`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/motion -m "$mFiMSC_val" -r
        fi

        if [ $mFiDS -eq 1 ] && [ "$port2" == "mFiDS" ]
        then
            #sensor abertura porta
            mFiDS_val=`cat /dev/input12`
            $PUBBIN -h $mqtthost $auth -t $topic/port2/door -m "$mFiDS_val" -r
        fi

        # port3
        if [ $mFiDS -eq 1 ] && [ "$port3" == "mFiDS" ]
        then
            #sensor abertura porta
            mFiDS_val=`cat /dev/input13`
            $PUBBIN -h $mqtthost $auth -t $topic/port3/door -m "$mFiDS_val" -r
        fi

        if [ $RTD -eq 1 ] && [ "$port3" == "RTD" ]
        then
            #sensor abertura porta
            RTD_val=`cat /proc/analog/value4`
            $PUBBIN -h $mqtthost $auth -t $topic/port3/temperature -m "$RTD_val" -r
        fi
    fi

    if [ "$mFiType" == "mPower" ] || [ "$mFiType" == "mPower Mini" ] || [ "$mFiType" == "mPower Pro" ]
    then

        log "Gathering mPower values."
        if [ $relay -eq 1 ]
        then
            # relay state
            for i in $(seq $PORTS)
            do
                relay_val=`cat /proc/power/relay$((i))`
                if [ $relay_val -ne 1 ]
                then
                  relay_val=0
                fi
                $PUBBIN -h $mqtthost $auth -t $topic/port$i/relay -m "$relay_val" -r
            done
        fi

        if [ $power -eq 1 ]
        then
            # power
            for i in $(seq $PORTS)
            do
                power_val=`cat /proc/power/active_pwr$((i))`
                power_val=`printf "%.1f" $power_val`
                $PUBBIN -h $mqtthost $auth -t $topic/port$i/power -m "$power_val" -r
            done
        fi

        if [ $energy -eq 1 ]
        then
            # energy consumption
            for i in $(seq $PORTS)
            do
                energy_val=`cat /proc/power/cf_count$((i))`
                energy_val=$(awk -vn1="$energy_val" -vn2="0.3125" 'BEGIN{print n1*n2}')
                energy_val=`printf "%.0f" $energy_val`
                $PUBBIN -h $mqtthost $auth -t $topic/port$i/energy -m "$energy_val" -r
            done
        fi

        if [ $voltage -eq 1 ]
        then
            # voltage
            for i in $(seq $PORTS)
            do
                voltage_val=`cat /proc/power/v_rms$((i))`
                voltage_val=`printf "%.1f" $voltage_val`
                $PUBBIN -h $mqtthost $auth -t $topic/port$i/voltage -m "$voltage_val" -r
            done
        fi

        if [ $current -eq 1 ]
        then
            # current
            for i in $(seq $PORTS)
            do
                current_val=`cat /proc/power/i_rms$((i))`
                current_val=`printf "%.1f" $current_val`
                $PUBBIN -h $mqtthost $auth -t $topic/port$i/current -m "$current_val" -r
            done
        fi

        if [ $lock -eq 1 ]
        then
            # lock
            for i in $(seq $PORTS)
            do
                port_val=`cat /proc/power/lock$((i))`
                $PUBBIN -h $mqtthost $auth -t $topic/port$i/lock -m "$port_val" -r
            done
        fi

        if [ $pf -eq 1 ]
        then
            # pf
            for i in $(seq $PORTS)
            do
                pf_val=`cat /proc/power/pf$((i))`
                pf_val=`printf "%.2f" $pf_val`
                $PUBBIN -h $mqtthost $auth -t $topic/port$i/pf -m "$pf_val" -r
            done
        fi
    fi

    if [ $stat -eq 1 ]
    then
      if [ $SLOWUPDATECOUNTER -le 0 ]
      then
          LOAD1=`awk '{print $1}' /proc/loadavg`
          LOAD5=`awk '{print $2}' /proc/loadavg`
          LOAD15=`awk '{print $3}' /proc/loadavg`
          $PUBBIN -h $mqtthost $auth -t $topic/\$stats/load1 -m "$LOAD1" -r
          $PUBBIN -h $mqtthost $auth -t $topic/\$stats/load5 -m "$LOAD5" -r
          $PUBBIN -h $mqtthost $auth -t $topic/\$stats/load15 -m "$LOAD15" -r

          UPTIME=`awk '{print $1}' /proc/uptime`
          $PUBBIN -h $mqtthost $auth -t $topic/\$stats/uptime -m "$UPTIME" -r
          SLOWUPDATECOUNTER=$((SLOWUPDATENUMBER))
      else
          SLOWUPDATECOUNTER=$((SLOWUPDATECOUNTER-1))
      fi
    fi

done
