#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

TMP=/tmp/zones
mkdir -p $TMP
cd $TMP
rm -f *.zone
wget http://www.ipdeny.com/ipblocks/data/countries/all-zones.tar.gz
tar zxvf all-zones.tar.gz
rm all-zones.tar.gz

# delete iptables geoallow rule if exists
rule=$( iptables -vnL --line-numbers |grep geoallow |awk '{print $1}' )
if [ -n "$rule" ]; then
        iptables -D INPUT $rule
fi

# delete geoallow ipset list if exists
ipset list geoallow > /dev/null 2>&1
if [ $? = "0" ]; then
        ipset destroy geoallow
fi

# create geoallow ipset list
ipset create geoallow hash:net

# populate geoallow ipset list
echo ""
echo "generating list of IPs to allow.  this may take a while"
echo ""

FILENAME=""
for country in nl $@ ; do
        FILENAME=${FILENAME}${country}_
        for ip in $( cat ./$country.zone ); do
                ipset -A geoallow $ip
        done
done

mkdir -p /etc/ipset

#remove last char of filename and save
ipset save > /etc/ipset/${FILENAME%?}.ipset

ln -s /etc/ipset/${FILENAME%?}.ipset /etc/ipset/current.ipset

# add iptables geoallow rule
iptables -I INPUT -m set ! --match-set geoallow src -j DROP


# display iptables rules
iptables -vnL --line-number

rm -Rf $TMP

cd -

mkdir -p /usr/share/netfilter-persistent/plugins.d

cp 14-my-ipset /usr/share/netfilter-persistent/plugins.d/14-my-ipset 
