#!/bin/bash

# update_tag.sh <instance_name>
export instance_name=$1
export zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
export tag="fantasy-server-slave"

gcloud compute instances add-tags ${instance_name} \
    --zone ${zone} \
    --tags ${tag}

