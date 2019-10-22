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

FROM alpine:3.10

RUN apk update \
    && apk upgrade \
    && apk add --no-cache curl jq \
    && rm -f /etc/apk/repositories \
    && apk update

COPY k8s-waiter.sh /wait.sh

RUN chgrp -R 0 /wait.sh && \
    chmod -R g=u /wait.sh

USER 1000

CMD [ "/wait.sh" ]