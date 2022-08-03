#!/bin/bash

# update_ig_port_for_instance.sh <instance_name>

export instance_name=$1
export zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
# export instance_name="fantasy-southamerica-gamesvr-01-master-1"
export instance_group="${instance_name}-ig"


export named_port_list="port-8099:8099,port-30031:30031"
gcloud compute instance-groups set-named-ports ${instance_group} --named-ports=${named_port_list} --zone=${zone}