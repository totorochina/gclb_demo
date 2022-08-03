#!/bin/bash
# create_ig_instance.sh <instance name>

# 定义所需端口和其它变量
export named_port_list="port-8099:8099,port-30031:30031,port-30028:30028"

# export instance_name="fantasy-southamerica-gamesvr-01-master-1"
export instance_name=$1
export instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="value(EXTERNAL_IP)")
export zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
export instance_group="${instance_name}-ig"

# 创建非托管实例组
gcloud compute instance-groups unmanaged create ${instance_group} \
    --zone=${zone}

gcloud compute instance-groups set-named-ports ${instance_group} --named-ports=${named_port_list} --zone=${zone}

# 添加实例入组
gcloud compute instance-groups unmanaged add-instances ${instance_group} \
    --zone=${zone} \
    --instances=${instance_name}