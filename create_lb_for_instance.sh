#!/bin/bash
# create_lb_for_instance.sh <instance name>

# 定义所需端口和其它变量
export fe_port_list=("1883" "3389" "5222" "5432" "5671" "5672" "5900" "5901" "6379" "8085" "8099" "9092" "9200" "9300")
export server_port_list1=($(seq 30025 30038))
export server_port_list2=($(seq 30039 30052))
export server_port_list3=($(seq 30053 30066))
export server_port_list4=($(seq 30067 30070))
export named_port_list=$(seq 30025 30070 | xargs -I {} echo -n port-{}:{}, | sed s/,$//g)

# export instance_name="fantasy-southamerica-gamesvr-01-master-1"
export instance_name=$1
export instance_public_ip=$(gcloud compute instances list --filter="name=gcptpebas01" --format="value(EXTERNAL_IP)")
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

# 创建每个实例所需的4个ip，如需逃生通道则为8个
ipv4_list=()
for i in $(seq 1 8)
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
# 操作完server_port_list1后，继续执行server_port_list2～4

export ipv4_1=${ipv4_list[1]} # 注意修改
export ipv4_2=${ipv4_list[2]} # 注意修改
# echo ${ipv4}
echo ${server_port_list1} # 注意修改
for i in $(seq 1 ${#server_port_list1[@]}) # 注意修改
do
	port=${server_port_list1[i]} # 注意修改
	fe_port=${fe_port_list[i]}
	backend_name="fantasy-${fe_port}-${port}"
	health_check_name="tcp-hc-${port}"
	port_name="port-${port}"
	target_proxy_name="fantasy-tp-${port}"
	# ipv4="ipv4-${instance_name}-${port}"
	forwarding_rule_name="forwarding-rule-${instance_name}-${port}"

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
	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_1} \
	    --ports ${fe_port}

	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_2} \
	    --ports ${fe_port}

	echo ${ipv4_1}:${fe_port} ${instance_public_ip}:${port}
	echo ${ipv4_2}:${fe_port} ${instance_public_ip}:${port}
done

export ipv4_1=${ipv4_list[3]} # 注意修改
export ipv4_2=${ipv4_list[4]} # 注意修改
# echo ${ipv4}
echo ${server_port_list2} # 注意修改
for i in $(seq 1 ${#server_port_list2[@]}) # 注意修改
do
	port=${server_port_list2[i]} # 注意修改
	fe_port=${fe_port_list[i]}
	backend_name="fantasy-${fe_port}-${port}"
	health_check_name="tcp-hc-${port}"
	port_name="port-${port}"
	target_proxy_name="fantasy-tp-${port}"
	# ipv4="ipv4-${instance_name}-${port}"
	forwarding_rule_name="forwarding-rule-${instance_name}-${port}"

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
	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_1} \
	    --ports ${fe_port}

	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_2} \
	    --ports ${fe_port}

	echo ${ipv4}:${fe_port} ${instance_public_ip}:${port}
done

export ipv4_1=${ipv4_list[5]} # 注意修改
export ipv4_2=${ipv4_list[6]} # 注意修改
# echo ${ipv4}
echo ${server_port_list3} # 注意修改
for i in $(seq 1 ${#server_port_list3[@]}) # 注意修改
do
	port=${server_port_list3[i]} # 注意修改
	fe_port=${fe_port_list[i]}
	backend_name="fantasy-${fe_port}-${port}"
	health_check_name="tcp-hc-${port}"
	port_name="port-${port}"
	target_proxy_name="fantasy-tp-${port}"
	# ipv4="ipv4-${instance_name}-${port}"
	forwarding_rule_name="forwarding-rule-${instance_name}-${port}"

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
	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_1} \
	    --ports ${fe_port}

	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_2} \
	    --ports ${fe_port}

	echo ${ipv4}:${fe_port} ${instance_public_ip}:${port}
done

export ipv4_1=${ipv4_list[7]} # 注意修改
export ipv4_2=${ipv4_list[8]} # 注意修改
# echo ${ipv4}
echo ${server_port_list4} # 注意修改
for i in $(seq 1 ${#server_port_list4[@]}) # 注意修改
do
	port=${server_port_list4[i]} # 注意修改
	fe_port=${fe_port_list[i]}
	backend_name="fantasy-${fe_port}-${port}"
	health_check_name="tcp-hc-${port}"
	port_name="port-${port}"
	target_proxy_name="fantasy-tp-${port}"
	# ipv4="ipv4-${instance_name}-${port}"
	forwarding_rule_name="forwarding-rule-${instance_name}-${port}"

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
	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_1} \
	    --ports ${fe_port}

	gcloud compute forwarding-rules create ${forwarding_rule_name} \
	    --global \
	    --target-tcp-proxy ${target_proxy_name} \
	    --address ${ipv4_2} \
	    --ports ${fe_port}
	    
	echo ${ipv4}:${fe_port} ${instance_public_ip}:${port}
done