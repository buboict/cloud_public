#!/usr/bin/env python3

import netaddr
import pandas as pd
import argparse
import os
import subprocess


# initiate the parser
parser = argparse.ArgumentParser(description='Convert ip2location CSV to ipset.')
parser.add_argument('--csv', help='input measurment csv file', required=True)
parser.add_argument('--countrycodes', nargs='+', help='e.g. NL DE ', required=True)
parser.add_argument('--ipset_dir', help='output ipset directory', required=True)

args = parser.parse_args()

ipset = '_'.join(args.countrycodes)
ipset += '.ipset'
ipset = os.path.join(args.ipset_dir,ipset)

def dec2ip(dec):
  return str(netaddr.IPAddress(int(dec)))

df = pd.read_csv(args.csv)

df.columns = ['startip', 'endip', 'code', 'country' ]

df = df[df['code'].isin(args.countrycodes)]

cidrs_list = [netaddr.iprange_to_cidrs(dec2ip(start), dec2ip(end)) for start, end in zip(df['startip'], df['endip'])]

#all addresses for the host
all_addresses =  subprocess.check_output('hostname -I', shell=True).decode('utf-8').split()
local_machine =  any(map(lambda s: s.startswith('192.168.'),all_addresses))
    

with open(ipset,'w') as out:
  out.write('create geoallow hash:net family inet hashsize 8192 maxelem 65536\n')
  if local_machine:
      out.write('add geoallow 192.168.2.0/24\n')
  for cidrs in cidrs_list:
    for cidr in cidrs:
      out.write('add geoallow '+ str(cidr)+'\n')

