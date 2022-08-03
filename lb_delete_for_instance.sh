#!/bin/bash

# lb_delete_for_instance.sh <instance name>

# 定义所需端口和其它变量
export fe_port="8099"
export port="30031"

export instance_name=$1
export instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="value(EXTERNAL_IP)")
export zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
export instance_group="${instance_name}-ig"

export forwarding_rule_name="fr-${instance_name}-${port}"
# if [[ "$instance_name" == *"us-central"* ]]
# then
# 	export forwarding_rule_name="forwarding-rule-${instance_name}-${port}"
# fi

export target_proxy_name="${instance_name}-tp-${port}"
export backend_name="${instance_name}-${fe_port}-${port}"

# 移除LB的FE
gcloud compute forwarding-rules delete ${forwarding_rule_name}-1 ${forwarding_rule_name}-2 --global --quiet

# 删除LB的FE IP
for i in $(seq 1 2)
do
	ipv4="ipv4-${instance_name}-${i}"
	gcloud compute addresses delete ${ipv4} \
    --global --quiet
done

# 移除LB的Target proxy
gcloud beta compute target-tcp-proxies delete ${target_proxy_name} --global --quiet

# 移除后台服务里的非托管实例组
# gcloud compute backend-services remove-backend ${backend_name}

# 删除后台服务
gcloud compute backend-services delete ${backend_name} --global --quiet

# 移除组中的实例
gcloud compute instance-groups unmanaged remove-instances ${instance_group} \
    --zone=${zone} \
    --instances=${instance_name} \
    --quiet

# 删除实例组
gcloud compute instance-groups unmanaged delete ${instance_group} --zone ${zone} --quiet