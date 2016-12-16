require './echo_api'
require 'zipkin-tracer'
run Sinatra::Application

# Encoding: utf-8

Faraday.default_connection_options = { ssl: { verify: false } }

config = {
:service_name => 'echo-api',
:service_port => 9292,
:sample_rate => 1.0,
:json_api_host => ENV['HAWKULAR_ENDPOINT']
}

use ZipkinTracer::RackHandler, config
