#!/bin/bash
# create_hc.sh

# 为每个后端端口配置健康检查，仅执行一次
for port in 30028 30031
do
	# 创建TCP健康检查
	gcloud compute health-checks create tcp tcp-hc-${port} --port ${port}
done