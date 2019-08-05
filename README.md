# k8s-waiter

A simple alpine container which uses the Kubernetes API to wait for a given service to be available.

This allows you to use existing, recommended tools like `readinessProbe`s and `livelinessProbe`s to ensure a service is running property, and then use this container as an `InitContainer` to wait for those probes to be `Ready`.

This script is based on [this cool article](https://blog.giantswarm.io/wait-for-it-using-readiness-probes-for-service-dependencies-in-kubernetes/).

### Usage

First, define the service you need as a dependency:

```yaml
# Your app's user service
apiVersion: v1
kind: Service
metadata:
  name: user
spec:
  ports:
    - port: 5000
      targetPort: 3000
  selector:
    app: user
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: user
spec:
  replicas: 3
  selector:
    matchLabels:
      app: user
template:
    metadata:
      labels:
        app: user
    spec:
      containers:
        - name: user
          image: organization/user-service:1.2.3
          ports: 
            - name: http
              containerPort: 3000
              protocol: TCP
          # This readiness probe tells Kubernetes when your service is ready to serve requests.
          # This can happen after you've initialized configuration, a database connection, etc.
          # When your service is "ready" it will be added to the `Service`s endpoints and `k8s-waiter` will exit
          readinessProbe:
            httpGet:
                path: /healthz
                port: http
            # The readiness probe is considered to be in the `Failed` state until `initialDelaySeconds` has passed
            initialDelaySeconds: 5
            periodSeconds: 5
```

Define a `Pod`, or `Deployment` with the `k8s-waiter` `InitContainer`, and boom! You're done!

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysite
spec:
  replicas: 3
  selector:
    matchLabels:
      app: frontend
template:
    metadata:
      labels:
        app: frontend
    spec:
      serviceAccountName: k8s-waiter
      containers:
        - name: web
          image: organization/frontend-service:3.1.2
          ports: 
            - name: http
              containerPort: 80
              protocol: TCP
      initContainers:
        - name: ensure-user-svc
          image: deciphernow/k8s-waiter
          env:
            - name: NAMESPACE
              value: default
            - name: SERVICE
              value: user
            # Wait 5 seconds before checking the state of the service again
            - name: DELAY
              value: "5"
            # PRE_DELAY is the time which the container waits before even beginning to check if the service is considered "ready"
            - name: PRE_DELAY
              value: "2"
            # POST_DELAY is the time which the container waits even after the service is considered "ready"
            - name: POST_DELAY
              value: "10"
```

### License

Copyright 2019 Decipher Technology Studios. Licensed under the Apache License, Version 2.0.

Details may be found in the license header at the top of every source file in this repository