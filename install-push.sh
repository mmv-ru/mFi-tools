#!/usr/bin/sh

if [ "$1" == "" ] ; then
    echo "Usage: install-push.sh <user>@<mfi-dev>"
    exit
fi

MY_PATH="`dirname \"$0\"`"              # relative
cd "$MY_PATH"
if [ -z "$MY_PATH" ] ; then
  echo "error: for some reason, the \"${MY_PATH}\" is not accessible"
  exit 1  # fail
fi

# mFi devices use old weak auth method so enable it
SSHOPT="-oKexAlgorithms=+diffie-hellman-group1-sha1"
SSHOPT="${SSHOPT} -oHostKeyAlgorithms=+ssh-rsa"
SSHOPT="${SSHOPT} -oCiphers=+aes256-cbc"
# Use persistent master connection to not enter password multiple times
SSHOPT="${SSHOPT} -oControlMaster=auto"
SSHOPT="${SSHOPT} -oControlPersist=5m"
SSHOPT="${SSHOPT} -oControlPath=~/.ssh/cm-%r@%h:%p"


ssh $SSHOPT $1 "sh /etc/persistent/mqtt/client/mqstop.sh"
scp $SSHOPT -r mqtt $1:/etc/persistent/
ssh $SSHOPT $1 sh /etc/persistent/mqtt/client/install-client.sh skip-download
ssh $SSHOPT $1 sh /etc/persistent/mqtt/client/mqrun.sh
