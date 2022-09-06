#!/bin/bash

_self="${0##*/}"

Help()
{
   # Display Help
   echo "Create tcp proxy lb for instance with arbitary port"
   echo
   echo "Syntax: ${_self} [-i|f|b|h]"
   echo "options:"
   echo "i     Set instance name"
   echo "f     Set frontend port/ports list."
   echo "b     Set backend port/ports list."
   echo "h     Print help."
   echo
}

while getopts i:f:b:h flag
do
    case "${flag}" in
        i) instance_name=${OPTARG};;
        f) fe_port=${OPTARG};;
        b) be_port=${OPTARG};;
        h) Help;exit;;
        \?) echo "Error: Invalid option";exit;;
    esac
done

if [ -z ${instance_name+x} ] || [ -z ${fe_port+x} ]
then
    Help
    exit;
fi

# If backend port will be equal to frontend if not set
be_port="${be_port:-${fe_port}}"

# convert to ports list
fe_port_array=($(echo ${fe_port} | sed 's/,/\n/g'))
be_port_array=($(echo ${be_port} | sed 's/,/\n/g'))

# $(for port in ${array[@]}; do echo -n port-${port}:${port}","; done)

# 定义所需端口与变量
_tmp=$(for port in ${fe_port_array[@]}; do echo -n port-${port}:${port}","; done)
# chop the last comma
named_port_list=${_tmp%,}

# for i in $(seq 1 ${#fe_port_array[@]})
# do
# 	fe_port=${fe_port_array[i-1]}
#     be_port=${be_port_array[i-1]}

#     echo $i ${fe_port} ${be_port}
# done
# echo ${instance_name} ${fe_port_array[@]} ${be_port_array[@]} ${named_port_list}
# exit

# instance_name=$1
instance_public_ip=$(gcloud compute instances list --filter="name=${instance_name}" --format="value(EXTERNAL_IP)")
zone=$(gcloud compute instances list --filter="name=${instance_name}" --format "get(zone)" | rev | cut -d'/' -f1 | rev)
instance_group="${instance_name}-group"

# 创建非托管实例组
gcloud compute instance-groups unmanaged create ${instance_group} \
    --zone=${zone}

gcloud compute instance-groups set-named-ports ${instance_group} --named-ports=${named_port_list} --zone=${zone}

# 添加实例入组
gcloud compute instance-groups unmanaged add-instances ${instance_group} \
    --zone=${zone} \
    --instances=${instance_name}

# 创建LB使用的IP
ipv4="ipv4-lb-${instance_name}"
# 为每个实例创建多个所需的公网IP
gcloud compute addresses create ${ipv4} \
    --ip-version=IPV4 \
    --global
ipv4_ip=$(gcloud compute addresses list --filter="name=${ipv4}" --format "get(ADDRESS)")


for i in $(seq 1 ${#fe_port_array[@]})
do
	fe_port=${fe_port_array[i-1]}
    be_port=${be_port_array[i-1]}

    # 定义创建LB所需变量
    backend_name="${instance_name}-${fe_port}-${be_port}"
    health_check_name="tcp-hc-${be_port}"
    port_name="port-${be_port}"
    target_proxy_name="tp-${backend_name}"
    forwarding_rule_name="fr-${backend_name}"

    # 创建后台服务
    gcloud compute backend-services create ${backend_name} \
        --global-health-checks \
        --global \
        --protocol TCP \
        --health-checks ${health_check_name} \
        --timeout 1d \
        --port-name ${port_name}

    # 将非托管实例组加入后台服务
    gcloud compute backend-services add-backend ${backend_name} \
        --global \
        --instance-group ${instance_group} \
        --instance-group-zone ${zone} \
        --balancing-mode UTILIZATION \
        --max-utilization 1

    # 创建target proxy转发给后台服务并开启proxy protocol
    gcloud compute target-tcp-proxies create ${target_proxy_name} \
        --backend-service ${backend_name} \
        --proxy-header PROXY_V1

    # 将公网IP关联给forwarding-rule并指定前端端口
    gcloud compute forwarding-rules create ${forwarding_rule_name} \
        --global \
        --target-tcp-proxy ${target_proxy_name} \
        --address ${ipv4} \
        --ports ${fe_port} && \
        echo ${ipv4_ip}:${fe_port} ${instance_public_ip}:${be_port}

done