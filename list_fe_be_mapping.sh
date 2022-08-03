#!/bin/bash

export instance_name=$1
# export instance_name="fantasy-southamerica-gamesvr-01-master-1"

export instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="csv[no-heading](EXTERNAL_IP)")
export fe_ip_list=$(gcloud compute forwarding-rules list --filter="name~'.*${instance_name}\-.*'" --format="csv[no-heading](IP_ADDRESS)")
export backend=$(gcloud compute backend-services list --filter="name~'.*${instance_name}\-.*'" --format="csv[no-heading](NAME)")
export health=$(gcloud compute backend-services get-health ${backend} --global --format="get(status.healthStatus[0].healthState)")

for fe_ip in ${fe_ip_list}
do
	echo "${backend},${fe_ip}:8099,${instance_name},${instance_public_ip}:30031,${health}"
done