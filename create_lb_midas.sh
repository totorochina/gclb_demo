#!/bin/bash
# create_lb_midas.sh

# 定义所需端口和其它变量
export fe_port_list_na=($(seq 10001 10030))
export na_instance_list=($(seq 1 2 59 | xargs -I{} echo fantasy-us-central-gamesvr-01-master-{}))
export fe_port_list_sa=($(seq 10001 10025))
export sa_instance_list=($(seq 1 2 49 | xargs -I{} echo fantasy-southamerica-gamesvr-01-master-{}))
export port="30028"
port_name="port-${port}"
health_check_name="tcp-hc-30028"

# LB IPs have been created as
# glb-midas-callback-na-ip1
# glb-midas-callback-na-ip2
# glb-midas-callback-sa-ip1
# glb-midas-callback-sa-ip2

export na_ipv4_1="glb-midas-callback-na-ip1"
export na_ipv4_2="glb-midas-callback-na-ip2"
export na_ipv4_1_ip=$(gcloud compute addresses list --filter="name=${na_ipv4_1}" --format "get(ADDRESS)")
export na_ipv4_2_ip=$(gcloud compute addresses list --filter="name=${na_ipv4_2}" --format "get(ADDRESS)")

export sa_ipv4_1="glb-midas-callback-sa-ip1"
export sa_ipv4_2="glb-midas-callback-sa-ip2"
export sa_ipv4_1_ip=$(gcloud compute addresses list --filter="name=${sa_ipv4_1}" --format "get(ADDRESS)")
export sa_ipv4_2_ip=$(gcloud compute addresses list --filter="name=${sa_ipv4_2}" --format "get(ADDRESS)")

# NA
for i in $(seq 0 29)
# for i in $(seq 22 29)
# for i in $(seq 0 0)
do
    ipv4_1="glb-midas-callback-na-ip1"
    ipv4_2="glb-midas-callback-na-ip2"
    ipv4_1_ip=$(gcloud compute addresses list --filter="name=${ipv4_1}" --format "get(ADDRESS)")
    ipv4_2_ip=$(gcloud compute addresses list --filter="name=${ipv4_2}" --format "get(ADDRESS)")

    fe_port=${fe_port_list_na[i]}
    instance_name=${na_instance_list[i]}
    zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
    instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="value(EXTERNAL_IP)")
    instance_group="${instance_name}-ig"

    backend_name="midas-${instance_name}-${fe_port}-${port}"
    target_ssl_proxy_name="midas-${instance_name}-ssl-tp-${port}"
    forwarding_rule_name="midas-fr-${instance_name}-${port}"
    # break

    # 创建后台服务
    gcloud compute backend-services create ${backend_name} \
        --global-health-checks \
        --global \
        --protocol TCP \
        --health-checks ${health_check_name} \
        --timeout 30s \
        --port-name ${port_name}

    # 将非托管实例组加入后台服务
    gcloud compute backend-services add-backend ${backend_name} \
        --global \
        --instance-group ${instance_group} \
        --instance-group-zone ${zone} \
        --balancing-mode UTILIZATION \
        --max-utilization 1

    # 创建target ssl proxy
    gcloud compute target-ssl-proxies create ${target_ssl_proxy_name} \
        --backend-service ${backend_name} \
        --ssl-certificates "toweroffantasy-global-com" \
        --proxy-header=NONE

    # 将公网IP关联给forwarding-rule并指定前端端口
    gcloud compute forwarding-rules create ${forwarding_rule_name}-1 \
        --global \
        --target-ssl-proxy ${target_ssl_proxy_name} \
        --address ${ipv4_1} \
        --ports ${fe_port} && \
    	echo ${ipv4_1_ip}:${fe_port} ${instance_public_ip}:${port}

    gcloud compute forwarding-rules create ${forwarding_rule_name}-2 \
        --global \
        --target-ssl-proxy ${target_ssl_proxy_name} \
        --address ${ipv4_2} \
        --ports ${fe_port} && \
    	echo ${ipv4_2_ip}:${fe_port} ${instance_public_ip}:${port}
done


# SA
for i in $(seq 0 24)
# for i in $(seq 1 1)
do
    ipv4_1="glb-midas-callback-sa-ip1"
    ipv4_2="glb-midas-callback-sa-ip2"
    ipv4_1_ip=$(gcloud compute addresses list --filter="name=${ipv4_1}" --format "get(ADDRESS)")
    ipv4_2_ip=$(gcloud compute addresses list --filter="name=${ipv4_2}" --format "get(ADDRESS)")

    fe_port=${fe_port_list_sa[i]}
    instance_name=${sa_instance_list[i]}
    zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
    instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="value(EXTERNAL_IP)")
    instance_group="${instance_name}-ig"

    backend_name="midas-${instance_name}-${fe_port}-${port}"
    target_ssl_proxy_name="midas-${instance_name}-ssl-tp-${port}"
    forwarding_rule_name="midas-fr-${instance_name}-${port}"
    # break

    # 创建后台服务
    gcloud compute backend-services create ${backend_name} \
        --global-health-checks \
        --global \
        --protocol TCP \
        --health-checks ${health_check_name} \
        --timeout 30s \
        --port-name ${port_name}

    # 将非托管实例组加入后台服务
    gcloud compute backend-services add-backend ${backend_name} \
        --global \
        --instance-group ${instance_group} \
        --instance-group-zone ${zone} \
        --balancing-mode UTILIZATION \
        --max-utilization 1

    # 创建target ssl proxy
    gcloud compute target-ssl-proxies create ${target_ssl_proxy_name} \
        --backend-service ${backend_name} \
        --ssl-certificates "toweroffantasy-global-com" \
        --proxy-header=NONE

    # 将公网IP关联给forwarding-rule并指定前端端口
    gcloud compute forwarding-rules create ${forwarding_rule_name}-1 \
        --global \
        --target-ssl-proxy ${target_ssl_proxy_name} \
        --address ${ipv4_1} \
        --ports ${fe_port} && \
        echo ${ipv4_1_ip}:${fe_port} ${instance_public_ip}:${port}

    gcloud compute forwarding-rules create ${forwarding_rule_name}-2 \
        --global \
        --target-ssl-proxy ${target_ssl_proxy_name} \
        --address ${ipv4_2} \
        --ports ${fe_port} && \
        echo ${ipv4_2_ip}:${fe_port} ${instance_public_ip}:${port}
done