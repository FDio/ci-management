#!/bin/bash

hostname=$(grep search /etc/resolv.conf|cut -d' ' -f3)
FILE="/tmp/shimrun"
/bin/cat <<EOM >$FILE
hostname
docker image list
hostname
exit
EOM


echo 'foo'
#scp /tmp/shimrun root@172.17.0.2:/tmp/shimrun

#ssh root@172.17.0.2 </tmp/shimrun
ssh root@$hostname -p 6022 "ls /usr/local/bin"


