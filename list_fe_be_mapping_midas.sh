#!/bin/bash
# list_fe_be_mapping_midas.sh

# 定义所需端口和其它变量
export fe_port_list_na=($(seq 10001 10030))
export na_instance_list=($(seq 1 2 59 | xargs -I{} echo fantasy-us-central-gamesvr-01-master-{}))
export fe_port_list_sa=($(seq 10001 10025))
export sa_instance_list=($(seq 1 2 49 | xargs -I{} echo fantasy-southamerica-gamesvr-01-master-{}))
export port="30028"
port_name="port-${port}"
# health_check_name="tcp-hc-30028"

# LB IPs have been created as
# glb-midas-callback-na-ip1
# glb-midas-callback-na-ip2
# glb-midas-callback-sa-ip1
# glb-midas-callback-sa-ip2

# export na_ipv4_1="glb-midas-callback-na-ip1"
# export na_ipv4_2="glb-midas-callback-na-ip2"
# export na_ipv4_1_ip=$(gcloud compute addresses list --filter="name=${na_ipv4_1}" --format "get(ADDRESS)")
# export na_ipv4_2_ip=$(gcloud compute addresses list --filter="name=${na_ipv4_2}" --format "get(ADDRESS)")

# export sa_ipv4_1="glb-midas-callback-sa-ip1"
# export sa_ipv4_2="glb-midas-callback-sa-ip2"
# export sa_ipv4_1_ip=$(gcloud compute addresses list --filter="name=${sa_ipv4_1}" --format "get(ADDRESS)")
# export sa_ipv4_2_ip=$(gcloud compute addresses list --filter="name=${sa_ipv4_2}" --format "get(ADDRESS)")

# NA
for i in $(seq 0 29)
do
    ipv4_1="glb-midas-callback-na-ip1"
    ipv4_2="glb-midas-callback-na-ip2"
    ipv4_1_ip=$(gcloud compute addresses list --filter="name=${ipv4_1}" --format "get(ADDRESS)")
    ipv4_2_ip=$(gcloud compute addresses list --filter="name=${ipv4_2}" --format "get(ADDRESS)")

    fe_port=${fe_port_list_na[i]}
    instance_name=${na_instance_list[i]}
    instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="value(EXTERNAL_IP)")
    # instance_group="${instance_name}-ig"

    backend_name="midas-${instance_name}-${fe_port}-${port}"
    health=$(gcloud compute backend-services get-health ${backend_name} --global --format="get(status.healthStatus[0].healthState)")
    # target_ssl_proxy_name="midas-${instance_name}-ssl-tp-${port}"
    # forwarding_rule_name="midas-fr-${instance_name}-${port}"
    # break

	echo "${backend_name},${ipv4_1_ip}:${fe_port},${instance_name},${instance_public_ip}:${port},${health}"
	echo "${backend_name},${ipv4_2_ip}:${fe_port},${instance_name},${instance_public_ip}:${port},${health}"
done

# SA
for i in $(seq 0 24)
do
    ipv4_1="glb-midas-callback-sa-ip1"
    ipv4_2="glb-midas-callback-sa-ip2"
    ipv4_1_ip=$(gcloud compute addresses list --filter="name=${ipv4_1}" --format "get(ADDRESS)")
    ipv4_2_ip=$(gcloud compute addresses list --filter="name=${ipv4_2}" --format "get(ADDRESS)")

    fe_port=${fe_port_list_na[i]}
    instance_name=${na_instance_list[i]}
    zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
    instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="value(EXTERNAL_IP)")
    # instance_group="${instance_name}-ig"

    backend_name="midas-${instance_name}-${fe_port}-${port}"
    health=$(gcloud compute backend-services get-health ${backend_name} --global --format="get(status.healthStatus[0].healthState)")
    # target_ssl_proxy_name="midas-${instance_name}-ssl-tp-${port}"
    # forwarding_rule_name="midas-fr-${instance_name}-${port}"
    # break

	echo "${backend_name},${ipv4_1_ip}:${fe_port},${instance_name},${instance_public_ip}:${port},${health}"
	echo "${backend_name},${ipv4_2_ip}:${fe_port},${instance_name},${instance_public_ip}:${port},${health}"
done