#!/bin/bash

# ig_del_for_instance.sh <instance name>

# 定义所需端口和其它变量

export instance_name=$1
export zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
export instance_group="${instance_name}-ig"

export target_proxy_name="${instance_name}-tp-${port}"
export backend_name="${instance_name}-${fe_port}-${port}"

# 移除组中的实例
gcloud compute instance-groups unmanaged remove-instances ${instance_group} \
    --zone=${zone} \
    --instances=${instance_name} \
    --quiet

# 删除实例组
gcloud compute instance-groups unmanaged delete ${instance_group} --zone ${zone} --quiet