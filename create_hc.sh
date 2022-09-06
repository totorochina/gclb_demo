#!/bin/bash
# create_hc.sh <ports>
# create_hc.sh 7000 8000 17000 18000

ports_array=$@
# 为每个后端端口配置健康检查，仅执行一次
for port in ${ports_array}
do
	# 创建TCP健康检查
	gcloud compute health-checks create tcp tcp-hc-${port} --port ${port}
	# echo ${port}
done