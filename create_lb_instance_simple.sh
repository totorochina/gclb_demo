#!/bin/bash
# create_lb_instance_simple.sh <instance name>

# 定义所需端口和其它变量
export fe_port="8099"
# for go-mmproxy
export port="8099"
# export port="30031"
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

# 创建每个实例连同逃生通道所需的2个ip
ipv4_list=()
for i in $(seq 1 2)
do
	ipv4="ipv4-${instance_name}-${i}"
	# 为每个实例创建多个所需的公网IP
	gcloud compute addresses create ${ipv4} \
    --ip-version=IPV4 \
    --global
    ipv4_list+=(${ipv4})
done
echo ${ipv4_list}

# 为每一组后端端口配置相应的LB规则，关联对应的前端IP和端口

export ipv4_1=${ipv4_list[0]}
export ipv4_2=${ipv4_list[1]}
export ipv4_1_ip=$(gcloud compute addresses list --filter="name=${ipv4_1}" --format "get(ADDRESS)")
export ipv4_2_ip=$(gcloud compute addresses list --filter="name=${ipv4_2}" --format "get(ADDRESS)")

backend_name="${instance_name}-${fe_port}-${port}"

# for go-mmproxy
health_check_name="hc-tcp-port-8099-pp"
# health_check_name="tcp-hc-${port}"
port_name="port-${port}"
target_proxy_name="${instance_name}-tp-${port}"
# ipv4="ipv4-${instance_name}-${port}"
forwarding_rule_name="fr-${instance_name}-${port}"

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

# 创建target proxy用于转发到后台服务
gcloud compute target-tcp-proxies create ${target_proxy_name} \
    --backend-service ${backend_name} \
    --proxy-header PROXY_V1

# 将公网IP关联给forwarding-rule并指定前端端口
gcloud compute forwarding-rules create ${forwarding_rule_name}-1 \
    --global \
    --target-tcp-proxy ${target_proxy_name} \
    --address ${ipv4_1} \
    --ports ${fe_port} && \
	echo ${ipv4_1_ip}:${fe_port} ${instance_public_ip}:${port}

gcloud compute forwarding-rules create ${forwarding_rule_name}-2 \
    --global \
    --target-tcp-proxy ${target_proxy_name} \
    --address ${ipv4_2} \
    --ports ${fe_port} && \
	echo ${ipv4_2_ip}:${fe_port} ${instance_public_ip}:${port}