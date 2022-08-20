import pandas as pd
import numpy as np
import subprocess
from io import StringIO

# dataframe for VM & its IP

# get_vm_cmd = """gcloud compute instances list \
#     --filter="(tags.items='fantasy-server' NOT tags.items='fantasy-server-roomsvr' NOT tags.items='fantasy-server-slave' AND name~'.*gamesvr.*master.*')" \
#     --format "csv[no-heading](NAME,ZONE,INTERNAL_IP,EXTERNAL_IP)"
# """

get_vm_cmd = """gcloud compute instances list \
    --format "csv[no-heading](NAME,ZONE,INTERNAL_IP,EXTERNAL_IP)"
"""

output = subprocess.getoutput(get_vm_cmd)
# print(output)

df_vm = pd.read_csv(StringIO(output), names=['instance','zone','internal_ip','external_ip'])
# df_vm.head()

# Dataframe for Backend Services

get_bs_cmd = """gcloud compute backend-services list \
    --format "csv[no-heading](name,BACKENDS,portName)"
"""

output = subprocess.getoutput(get_bs_cmd)
# print(output)

df_bs = pd.read_csv(StringIO(output), names=['service','instance_group','port'])
# df_bs.head()

# df_bs.port.values

# Dataframe for forwarding-rules

get_fr_cmd = """gcloud compute forwarding-rules list \
    --format "csv[no-heading](name,IP_ADDRESS,IP_PROTOCOL,portRange,ports,TARGET)"
"""

output = subprocess.getoutput(get_fr_cmd)
# print(output)

df_fr = pd.read_csv(StringIO(output), names=['forwarding_rule','lb_ip', 'protocol', 'port_range', 'ports', 'target_proxy'])
# df_fr.head()

df_fr.loc[df_fr.port_range.isna(), 'port_range'] = df_fr[df_fr.port_range.isna()].ports

df_fr.drop('ports', axis=1, inplace=True)

# Dataframe for target proxies, incluing TCP/SSL/HTTP/HTTPs, currently no target-pool/target-instance

get_tp_tcp_cmd = """gcloud compute target-tcp-proxies list \
    --format "csv[no-heading](name,service)"
"""

output = subprocess.getoutput(get_tp_tcp_cmd)
# print(output)

df_tp_tcp = pd.read_csv(StringIO(output), names=['target_proxy','service'])
# df_tp_tcp.head()

get_tp_ssl_cmd = """gcloud compute target-ssl-proxies list \
    --format "csv[no-heading](name,service)"
"""

output = subprocess.getoutput(get_tp_ssl_cmd)
# print(output)

df_tp_ssl = pd.read_csv(StringIO(output), names=['target_proxy','service'])
# df_tp_ssl.head()

df_tcp_tp_all = pd.concat([df_tp_tcp, df_tp_ssl]).reset_index(drop=True)
# df_tcp_tp_all.head()

# HTTPs target proxy includes url-maps, which needs another reference from url-maps before getting BackendServices

get_tp_http_cmd = """gcloud compute target-http-proxies list \
    --format "csv[no-heading](name,URL_MAP)"
"""

output = subprocess.getoutput(get_tp_http_cmd)
# print(output)

df_tp_http = pd.read_csv(StringIO(output), names=['target_proxy','url-map'])
# df_tp_http.head()

get_tp_https_cmd = """gcloud compute target-https-proxies list \
    --format "csv[no-heading](name,URL_MAP)"
"""

output = subprocess.getoutput(get_tp_https_cmd)
# print(output)

df_tp_https = pd.read_csv(StringIO(output), names=['target_proxy','url-map'])
# df_tp_https.head()

df_tp_http_https = pd.concat([df_tp_http, df_tp_https])
# df_tp_http_https.head()

get_url_maps_cmd = """gcloud compute url-maps list \
    --format "csv[no-heading](name,DEFAULT_SERVICE)"
"""

output = subprocess.getoutput(get_url_maps_cmd)
# print(output)

df_url_maps = pd.read_csv(StringIO(output), names=['url-map','service'])
df_url_maps.head()

# Here we only want service name, ignoring backendServices/backendBuckets

df_url_maps['service'] = df_url_maps.service.apply(lambda x: x.split('/')[-1] if isinstance(x, str) else x)
# df_url_maps.head()

# df_tp_http_https.shape, df_url_maps.shape

df_tp_http_https.reset_index(drop=True)

df_https_tp_bs = pd.merge(df_tp_http_https, df_url_maps, how='left', left_on='url-map', right_on='url-map')
# df_https_tp_bs.head()

df_tp_bs = pd.concat([df_tcp_tp_all, df_https_tp_bs[['target_proxy', 'service']]]).reset_index(drop=True)
# df_tp_bs.head()

df_tmp1 = pd.merge(df_fr, df_tp_bs, how='left', left_on='target_proxy', right_on='target_proxy')
# df_tmp1.head()

df_tmp1.loc[df_tmp1.target_proxy.str.contains('/'), 'service'] = df_tmp1[df_tmp1.target_proxy.str.contains('/')].target_proxy.apply(lambda x: x.split('/')[-1])

df_tmp1[df_tmp1.service == 'lb-midas-callback-na']

df_bs[df_bs.service == 'lb-midas-callback-na'].values

df_tmp = pd.merge(df_tmp1, df_bs, how='left', left_on='service', right_on='service')
# df_tmp.head()

# df_tmp1.shape, df_tmp.shape

df_tmp.instance_group.values

# from google.cloud import compute_v1
# ig_client = compute_v1.InstanceGroupsClient()
# ig_client.list_instances(project=project_id, zone='us-central1-b', instance_group='fantasy-us-central-gamesvr-01-master-41-ig')


instance_group_ary = df_tmp[df_tmp.instance_group.notna()].instance_group.values

# instance_group_ary

# One backend service can have multiple instance groups, so we have to split them to get instance group to VM mapping.

tmp_ary = []
for ig in instance_group_ary:
    if ',' in ig:
        tmp_ary += ig.split(',')
    else:
        tmp_ary.append(ig)
instance_group_ary = np.unique(np.array(tmp_ary))
# instance_group_ary

instance_groups = []
instances = []
for ig in instance_group_ary:
    zone = ig.split('/')[0]
    ig_name = ig.split('/')[-1]
    # print(zone, ig_name)
    # zone
    if len(zone.split('-')) == 3:
        cmd = """gcloud compute instance-groups list-instances {}\
            --zone {} --format "csv[no-heading,separator='@'](NAME,namedPorts)"
        """.format(ig_name, zone)
    # region
    else:
        cmd = """gcloud compute instance-groups list-instances {}\
            --region {} --format "csv[no-heading,separator='@'](NAME,namedPorts)"
        """.format(ig_name, zone)
    output = subprocess.getoutput(cmd)
    tmp = output.split('\n')
    instances += tmp
    if len(tmp) > 1:
        instance_groups += [ig_name] * len(tmp)
    else:
        instance_groups += [ig_name]

namedports = [instance.split('@')[1] for instance in instances]
instances = [instance.split('@')[0] for instance in instances]

# len(instances), len(instance_groups), len(namedports)


df_vm_ig = pd.DataFrame({'instance': instances, 'instance_group': instance_groups, 'namedports': namedports})
# df_vm_ig.head()

# df_tmp.head()

# df_tmp.instance_group.values

# Prepare to join on instance_group

df_tmp['instance_group'] = df_tmp.instance_group.apply(lambda x: x.split('/')[-1] if isinstance(x, str) else x)
# df_tmp.head()

# df_vm_ig.shape, df_tmp.shape

# df_vm_ig.head()

# df_tmp.instance_group.values

df_tmp2 = pd.merge(df_tmp, df_vm_ig, on='instance_group', how='left')
# df_tmp2.head()

# df_tmp2.shape, df_vm.shape

# df_tmp2.head()

df_stat = pd.merge(df_tmp2, df_vm, how='left', left_on='instance', right_on='instance')
# df_stat.head()

# df_stat.shape

# df_stat.port_range.unique()

# df_stat[df_stat.instance == 'fantasy-us-central-tlog01']

# df_vm[df_vm.instance == 'fantasy-us-central-tlog01']

df = df_stat[(df_stat.instance.notna() & df_stat.internal_ip.notna())][['instance', 'zone', 'internal_ip', 'external_ip', 'lb_ip', 'protocol', 'port_range', 'port', 'namedports']].drop_duplicates().reset_index(drop=True)
# df.head()

# df.shape

# df.port_range.unique()

# df.port.unique()

def port_range_transform(port_range):
    if isinstance(port_range, float):
        return port_range
    else:
        port_start = port_range.split('-')[0]
        port_end = port_range.split('-')[-1]
        if port_start == port_end:
            return port_start
        else:
            return port_range

df['port_range'] = df.port_range.apply(lambda x: port_range_transform(x)).fillna(0).astype('float').astype('int')
df['port'] = df.port.fillna('0')

df = df.rename(columns={"port_range": "frontend_port", "port": "backend_port"})
# df.head()

# For those backend_port is not a number, transform to number according to namedports mapping.

# df[df.backend_port.str.contains('[a-zA-Z]+')]

backend_port_ary = []
real_port_ary = []

for backend_port, namedports in zip(df['backend_port'].values, df['namedports'].values):
    # print(backend_port, namedports)
    if namedports:
        namedports = namedports.replace(';', ',')
        namedports_df = pd.DataFrame(eval("["+namedports+"]"), columns=['name', 'port'])
        # namedports_df = pd.DataFrame(eval(namedports), columns=['name', 'port'])
        # print(backend_port, ','.join(namedports_df.loc[namedports_df.name == backend_port].port.astype('str').to_list()))
        real_port_ary.append(','.join(namedports_df.loc[namedports_df.name == backend_port].port.astype('str').to_list()))
    else:
        # print(backend_port, namedports)
        real_port_ary.append('')
    backend_port_ary.append(backend_port)

# len(backend_port_ary), len(real_port_ary)

df['backend_port'] = real_port_ary

print(df.drop('namedports', axis=1))

df.drop('namedports', axis=1).to_csv('vm_lb_mapping.csv', index=False)