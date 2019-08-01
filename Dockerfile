FROM alpine:3.10

RUN apk add --no-cache curl jq

COPY k8s-waiter.sh /wait.sh

CMD [ "/wait.sh" ]