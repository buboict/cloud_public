#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


CSV=IP2LOCATION-LITE-DB1.CSV
TMP=/tmp/ip2loc

mkdir -p ${TMP}
rm -f ${TMP}/${CSV}.ZIP
wget -P ${TMP}  https://download.ip2location.com/lite/${CSV}.ZIP
unzip ${TMP}/${CSV}.ZIP -d ${TMP}

./iprange2cidr.py --csv ${TMP}/${CSV} --countrycodes 'NL' --ipset_dir /etc/ipset

rm -Rf ${TMP}

rm /etc/ipset/current.ipset
cat /etc/ipset/*.ipset > /etc/ipset/current.ipset  2>/dev/null

ipset restore -! < /etc/ipset/current.ipset 2> /dev/null

