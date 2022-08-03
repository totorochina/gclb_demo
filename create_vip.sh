#!/bin/bash

# create_vip.sh <ip_name1> <ip_name2> ...

ipv4_list="$@"
for ipv4 in ${ipv4_list}
do
	gcloud compute addresses create ${ipv4} \
    --ip-version=IPV4 \
    --global
 	# echo ${ipv4}
done