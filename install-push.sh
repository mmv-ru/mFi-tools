#!/usr/bin/sh

# mFi devices use old weak auth method so enable it
SSHOPT="-oKexAlgorithms=+diffie-hellman-group1-sha1"
# Use persistent master connection to not enter password multiple times
SSHOPT="${SSHOPT} -oControlMaster=auto"
SSHOPT="${SSHOPT} -oControlPersist=5m"
SSHOPT="${SSHOPT} -oControlPath=~/.ssh/cm-%r@%h:%p"


ssh $SSHOPT $1 "sh /etc/persistent/mqtt/client/mqstop.sh"
scp $SSHOPT -r mqtt $1:/etc/persistent/
ssh $SSHOPT $1 sh /etc/persistent/mqtt/client/install-client.sh skip-download
ssh $SSHOPT $1 sh /etc/persistent/mqtt/client/mqrun.sh
