#!/usr/bin/env sh
# This script waits for a given service to have Ready pods as determined by their readiness checks.
# It takes two required envvars: NAMEPSACE and SERVICE, an optional DELAY value, and requires a kubernetes service account with read acccess to the endpoints resource
# It needs to be run in a container with curl and jq

[ -z "$NAMESPACE" ] && echo 'No $NAMESPACE provided' && exit 1;
[ -z "$SERVICE" ] && echo 'No $SERVICE provided' && exit 1;

cacert="/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
tokenfile="/var/run/secrets/kubernetes.io/serviceaccount/token"

if test ! -f "$cacert" -o ! -f "$tokenfile"; then
    echo "No service account provided" && exit 1;
fi;

token=$(cat $tokenfile)

DELAY=${DELAY:-3}  # Sets default delay for checking service status to 3 seconds
POST_DELAY=${POST_DELAY:-0}  # Sets default delay after service is considered "ready"

# Check that there are more than zero ready endpoints
until [ $(curl -s --cacert $cacert --header "Authorization: Bearer $token" \
 https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/endpoints/$SERVICE \
	| jq -r '.subsets[].addresses | length') -ge "1" ]; do
    echo "Service not ready: $NAMESPACE:$SERVICE"
    echo "Waiting $DELAY seconds ..."
    sleep $DELAY
done;

echo "Found service!"

echo "Waiting for \$POST_DELAY: $POST_DELAY seconds..."
sleep $POST_DELAY