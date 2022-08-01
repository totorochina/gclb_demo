#!/bin/bash

export instance_name=$1
export zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
# export instance_name="fantasy-southamerica-gamesvr-01-master-1"
export instance_group="${instance_name}-ig"

export fe_port="8099"
export port="30031"
export backend_name="${instance_name}-${fe_port}-${port}"
export target_proxy_name="${instance_name}-tp-${port}"

export named_port_list="port-8099:8099,port-30031:30031"
export port_name="port-8099"
export health_check_name="hc-tcp-port-8099-pp"

gcloud compute instance-groups set-named-ports ${instance_group} --named-ports=${named_port_list} --zone=${zone}

gcloud compute backend-services update ${backend_name} \
	--global \
	--port-name ${port_name} \
	--health-checks ${health_check_name}

gcloud compute target-tcp-proxies update ${target_proxy_name} \
    --backend-service ${backend_name} \
    --proxy-header PROXY_V1


# gcloud compute backend-services describe ${backend_name} --global
# gcloud compute target-tcp-proxies describe ${target_proxy_name}
