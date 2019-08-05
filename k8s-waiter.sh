#!/usr/bin/env sh
#   Copyright 2019 Decipher Technology Studios
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

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

DELAY=${DELAY:-3}  # Sets default delay between checking service status to 3 seconds
PRE_DELAY=${PRE_DELAY:-0}  # Sets the delay time to wait before checking the service
POST_DELAY=${POST_DELAY:-0}  # Sets default delay after service is considered "ready"

echo "Waiting for \$PRE_DELAY: $PRE_DELAY seconds..."
sleep $PRE_DELAY

# Check that there are more than zero ready endpoints

# TODO: fix issue where a `default` serviceaccount will return unauthorized and jq will fail thus causing -ge to fail
until test $(curl -s --cacert $cacert --header "Authorization: Bearer $token" \
 https://kubernetes.default.svc/api/v1/namespaces/$NAMESPACE/endpoints/$SERVICE \
	| jq -r '.subsets[].addresses | length') -ge "1"; do
    echo "Service not ready: $NAMESPACE:$SERVICE"
    echo "Waiting $DELAY seconds ..."
    sleep $DELAY
done;

echo "Found service!"

echo "Waiting for \$POST_DELAY: $POST_DELAY seconds..."
sleep $POST_DELAY