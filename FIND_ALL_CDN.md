# Get project ids by billing ids
gcloud alpha billing projects list --billing-account 01C4E5-AAE5D1-C674BA --format "csv[no-heading](PROJECT_ID)"

# Get HTTPs LB for each project id
gcloud compute url-maps list --format "csv[no-heading](name,DEFAULT_SERVICE,pathMatchers.defaultService)"

# Get backend services with CDN enabled
gcloud compute backend-services list --format="csv[no-heading](NAME,enableCDN)"

# Get backend buckets with CDN enabled
gcloud compute backend-buckets list --format="csv[no-heading](NAME,enableCdn)"