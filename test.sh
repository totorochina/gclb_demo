#!/bin/bash

gcloud compute instances list \
    --filter="(tags.items='fantasy-server' NOT tags.items='fantasy-server-roomsvr' NOT tags.items='fantasy-server-slave' AND name~'.*gamesvr.*master.*')" \
    --format "csv[no-heading](NAME,ZONE,INTERNAL_IP,EXTERNAL_IP)"

gcloud compute backend-services list \
    --format "csv[no-heading](name,backends.group,portName)"

gcloud compute forwarding-rules list \
    --format "csv[no-heading](name,IPAddress,target)"

gcloud compute target-tcp-proxies list \
    --format "csv[no-heading](name,service)"