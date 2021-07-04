# About
This adds MQTT features to Ubiquiti Networks mFi devices.

This is version 3.2, which aims to comply with [homie MQTT convention](https://github.com/marvinroger/homie).

The implementation of the convention is not complete yet.


# Compatible Devices
- mPower Mini and mPower Outlet 3 or 8 Ports

- mFiTHS, mFiCS, mFiMSW, mFiMSC, mFiDS and RTD sensor

# Warning
Use at your own risk!

# Installation
Use a SSH client and connect to your mFi device.
~~Enter the following commands~~
*wget from mFi device unable to connect to github dye to not suport modern SSL protocol*

```
mkdir /var/etc/persistent/mqtt
wget --no-check-certificate -q https://raw.githubusercontent.com/mmv-ru/mFi-tools/master/mqtt/client/install-client.sh -O /var/etc/persistent/mqtt/install-client.sh;chmod 755 /var/etc/persistent/mqtt/install-client.sh;/var/etc/persistent/mqtt/install-client.sh

save
reboot
```
# Installation with broken wget

 1. Download sources from reposotory.
 2. Optionally, copy and edit config filed in mqtt/client folder (model.cfg mqtt.cfg mpower-pub.cfg)
 3. upload mqtt folder to /etc/persistent
```
scp -r mqtt ubnt@<device address>:/etc/persistent/
```

 4. Connect ssh to device
 5. Run installer `sh /etc/persistent/mqtt/client/install-client.sh`
 6. Edit config files in /etc/persistent/mqtt/client (model.cfg mqtt.cfg mpower-pub.cfg), if not edited already. (vi available)
 7. Run mqtt client `/etc/persistent/mqtt/client/mqrun.sh` and check it working.
 8. Save device config by command `save`

# Starting
```
/var/etc/persistent/mqtt/client/mqrun.sh
```
The script also starts automatically approx 3 minutes after booting the device (using rc.poststart).

# Stoping
```
/var/etc/persistent/mqtt/client/mqstop.sh
```

# Configuration
## MQTT
Edit the file `/var/etc/persistent/mqtt/client/mqtt.cfg` and configure your server, topic and refresh time. Setting topic, refresh, mqttusername and mqttpassword is not mandatory. Defaults are 
`topic=homie/[name of the mpower]` and `refresh=60` seconds

```
mqtthost=192.168.1.4
#refresh=60
#topic=my/topic
#mqttusername=myMqttUserName
#mqttpassword=myMqttPassword
port1=mFiTHS
port2=mFiCS
port3=
```
## Configuring transmitted node attributes
You can suppress certain attributes (such as voltage) by editing the file `mpower-pub.cfg`. Set value to `0` if you dont need the data.

```
#enable (1) or disable (0) properties here
relay=1
power=1
energy=1
lock=1
voltage=0
current=1
pf=1
stat=1
mFiTHS=1
mFiCS=1
mFiMSW=1
mFiMSC=1
mFiDS=1
RTD=1
```

# mPower Published data

The mPower device will publish messages every 60 seconds to different topics. Example:

```
homie/mpower-1/port1/relay=0
homie/mpower-1/port2/relay=1
homie/mpower-1/port3/relay=0
homie/mpower-1/port1/power=0.0
homie/mpower-1/port2/power=7.2
homie/mpower-1/port3/power=0.0
homie/mpower-1/port1/energy=0
homie/mpower-1/port2/energy=4
homie/mpower-1/port3/energy=8
homie/mpower-1/port1/voltage=0.0
homie/mpower-1/port2/voltage=234.9
homie/mpower-1/port3/voltage=0.0
homie/mpower-1/port1/current=0.0
homie/mpower-1/port2/current=4.6
homie/mpower-1/port3/current=0.0
```

Every SLOWUPDATENUMBER (default: 6) refresh

```
homie/mpower-1/$stats/uptime=2589629.67
homie/mpower-1/$stats/load1=0.58
homie/mpower-1/$stats/load5=0.54
homie/mpower-1/$stats/load15=0.5
```

Additionally - currently only at the start of the script - the device will also report:

```
homie/mpower-1/$homie=3.0.0
homie/mpower-1/$name=mpower-1
homie/mpower-1/$fw/version=MF.v2.1.11-mq-0.2
homie/mpower-1/$fw/name=mPower=MQTT
homie/mpower-1/$localip=192.168.1.26
homie/mpower-1/$mac=DC:9F:DB:18:00:A1
homie/mpower-1/$nodes=port1,port2,port3
homie/mpower-1/port1/relay/$settable=true
homie/mpower-1/port2/relay/$settable=true
homie/mpower-1/port3/relay/$settable=true
homie/mpower-1/port1/lock/$settable=true
homie/mpower-1/port2/lock/$settable=true
homie/mpower-1/port3/lock/$settable=true
```

# mPort Published data

The mPort device will publish messages every 60 seconds to different topics. Example:

```
homie/mport-1/port1/mFiTHS 28.610001
homie/mport-2/port2/mFiCS
homie/mport-3/port3/mFiMSW

or

homie/mport-3/port1/mFiMSW
homie/mport-3/port1/mFiDS
```


# Control sockets via MQTT
You can control the sockets by sending `0` or `1` to the topic `<topic chosen above>/port<number of socket>/relay/set`

You can lock the sockets by sending `0` or `1` to the topic `<topic chosen above>/port<number of socket>/lock/set`

# logfile
The tool logs into standard messages log.
```
tail -f /var/log/messages
```
# Integrating into Home Assistant

This is an example how to define Home Assistant / Hassio.io items:

# mPort

sensor:
  - platform: mqtt
    name: "Temperature"
    state_topic: "homie/mport-1/port1/mFiTHS"
    unit_of_measurement: "Celcius"
    icon: mdi:temperature-celsius
    value_template: "{{ value | round(2) }}"

# mPower

switch:
  - platform: mqtt
    name: "mPower-1"
    state_topic: "homie/mpower-1/port1/relay"
    command_topic: "homie/mpower-1/port1/relay/set"
    payload_on: "1"
    payload_off: "0"
    retain: true  
```
# Integrating into openHAB (Not Tested)

This is an example how to define openHAB items:

```
Switch switchmp "My mpower switch" { mqtt=">[mosquitto:homie/mpower1/port1/relay/set:command:ON:1],>[mosquitto:homie/mpower1/port1/relay/set:command:OFF:0],<[mosquitto:homie/mpower1/port1/relay:state:MAP(mpowerrelay.map)]"}
Number energymp "Energy consumption [%d Wh]" { mqtt="<[mosquitto:homie/mpower1/port1/energy:state:default]" }
Number powermp "Current power [%.1f W]" { mqtt="<[mosquitto:homie/mpower1/port1/power:state:default]" }
```

You need a `mpowerrelay.map` file:
```
0=OFF
1=ON
```
# Credits

This project provides some tools for Ubiquiti Networks mFi devices.

MQTT client Provides an MQTT client.

Setup examples for Home Assistant/Hassio.io and openHAB

Forked from https://github.com/unverbraucht/mFi-tools

which in turn is forked from https://github.com/maletazul/mFi-tools

which in turn is forked from https://github.com/magcode/mpower-tools
