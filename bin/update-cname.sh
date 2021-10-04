#!/bin/bash

usage(){
    echo "Usage: update-cname.sh <CNAME>"
    echo "Env vars: CF_TOKEN CF_ZONE_ID CF_RECORDS"
    exit 1
}

[ -z "$1" ] && usage

for x in ${CF_TOKEN} ${CF_ZONE_ID} ${CF_RECORDS}; do
    [ -z "${x}" ] && usage
done

CF_ENDPOINT="https://api.cloudflare.com/client/v4"
CURRENT="/tmp/update-cname-$(date +%Y%m%d-%H%M%S).current"
RESULTS="/tmp/update-cname-$(date +%Y%m%d-%H%M%S).results"
CONTENT="${1}"

# https://api.cloudflare.com/#dns-records-for-a-zone-list-dns-records
curl -s -X GET "${CF_ENDPOINT}/zones/${CF_ZONE_ID}/dns_records?type=CNAME" \
    -H "Content-Type:application/json" \
    -H "Authorization: Bearer ${CF_TOKEN}" \
    > ${CURRENT}

for id in ${CF_RECORDS}; do
    name=$(cat ${CURRENT} | jq -r ".result[] | select(.id | contains(\"${id}\")) | .name")
    current_content=$(cat ${CURRENT} | jq -r ".result[] | select(.id | contains(\"${id}\")) | .content")
    [ "${current_content}" == "${CONTENT}" ] && { echo "No change for ${name}, noop"; continue; }

    # https://api.cloudflare.com/#dns-records-for-a-zone-update-dns-record
    curl -s -X PUT "${CF_ENDPOINT}/zones/${CF_ZONE_ID}/dns_records/${id}" \
        -H "Content-Type:application/json" \
        -H "Authorization: Bearer ${CF_TOKEN}" \
        -d @- << EOF >> ${RESULTS}
    {
        "type": "CNAME",
        "name": "${name}",
        "content": "${CONTENT}",
        "ttl": 1,
        "proxied": false
    }
EOF
done
