echo-api
========

Sinatra app that returns back info about HTTP/1 requests.

https://echo-api.3scale.net/ 

## Container image

A container image can be found at quay.io/3scale/echoapi:stable.

## Running on Openshift/Istio

You can find contributed templates for deploying `echo-api` on Openshift
and Istio in the `contrib` directory.

## Running with Jaeger support

Just pass in the environment variables below to the program:

- `OPENTRACING_TRACER` set to `jaeger`.
- `JAEGER_SERVICE_NAME` can optionally be set, default is `echo-api`.
- `JAEGER_AGENT_HOST` set to the hostname/address of the Jaeger's agent.
- `JAEGER_AGENT_PORT` set to the port where the Jaeger's agent listens.

The `JAGER_AGENT_HOST` and `JAEGER_AGENT_PORT` variables can be omitted for
a default local agent listening at `127.0.0.1` and port `6831`.
