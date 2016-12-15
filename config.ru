require './echo_api'
require 'zipkin-tracer'
run Sinatra::Application

# Encoding: utf-8

Faraday.default_connection_options = { ssl: { verify: false } }

config = {
:service_name => 'echo-api',
:service_port => 9292,
:sample_rate => 1.0,
:json_api_host => 'https://admin:password@hawkular-apm-openshift-infra.54.169.160.2.xip.io'
}

use ZipkinTracer::RackHandler, config
