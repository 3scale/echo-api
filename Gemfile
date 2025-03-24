# frozen_string_literal: true

source 'https://rubygems.org'

gem 'nokogiri', '~> 1'
gem 'puma'
gem 'rack', '~> 3'
gem 'rack-cors', require: 'rack/cors'
gem "rackup", "~> 2.2"
gem 'sinatra', '~> 4'

gem 'json'

# Opentracing
gem 'opentelemetry-instrumentation-rack', '~> 0.22', require: false
gem 'opentelemetry-instrumentation-sinatra', '~> 0.22', require: false
gem 'opentelemetry-exporter-otlp', require: false
gem 'opentelemetry-exporter-zipkin', require: false

group :development do
  gem 'shotgun'
end
