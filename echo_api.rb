# frozen_string_literal: true

# shotgun app.rb -p 9294

module EchoAPI
  VERSION = '1.1.0'.freeze
end

require 'rubygems'
require 'bundler'

Bundler.require

enable :logging
set :protection, except: [:json_csrf]

configure do
  set :server, :puma
  set :public_folder, 'tmp'
  enable :static
end


telemetry_exporter = ENV['OTEL_TRACES_EXPORTER'] || ENV['OPENTRACING_TRACER']
if telemetry_exporter
  telemetry_exporter = 'otlp' if telemetry_exporter == 'jaeger'

  ENV['OTEL_TRACES_EXPORTER'] = telemetry_exporter
  require 'opentelemetry/sdk'
  unless telemetry_exporter == 'console'
    host = ENV['JAEGER_AGENT_HOST'] || '127.0.0.1'
    port = ENV['JAEGER_AGENT_PORT']
    port ||= telemetry_exporter == 'zipkin' ? 6831 : 4318
    ENV['OTEL_EXPORTER_OTLP_ENDPOINT'] ||= "http://#{host}:#{port}"
    require "opentelemetry/exporter/#{telemetry_exporter}"
  end

  require 'opentelemetry/instrumentation/sinatra'

  OpenTelemetry::SDK.configure do |c|
    c.service_name = ENV['OTEL_SERVICE_NAME'] || ENV['JAEGER_SERVICE_NAME'] || 'echo-api'

    c.use 'OpenTelemetry::Instrumentation::Sinatra'
  end
end

# Enabling CORS
use Rack::Cors do
  allow do
    origins '*'
    resource '*', headers: :any, methods: %i[
      head options get post patch put delete
    ]
  end
end

ECHO_API_VERSION = (ENV['ECHO_API_BANNER'] ||
                    "echo-api/#{EchoAPI::VERSION}").freeze

after do
  headers['X-3scale-Echo-API'] = ECHO_API_VERSION
end

def all_methods(path, opts = {}, &block)
  get(path, opts, &block)
  post(path, opts, &block)
  put(path, opts, &block)
  delete(path, opts, &block)
  patch(path, opts, &block)
  options(path, opts, &block)
  head(path, opts, &block)
end

def get_headers
  env.select do |k, _v|
    k.start_with?('HTTP_') || k == 'CONTENT_LENGTH' || k == 'CONTENT_TYPE'
  end
end

# Constant to trim headers starting with the string below
ECHO_HEADER_PREFIX_SIZE = 'HTTP_ECHO_'.size

def echo_response
  body = request.body.read
  hash = Digest::SHA1.base64digest(body)
  # B64 encode if contains obviously non-printable character(s).
  if request.media_type == 'application/octet-stream' ||
     request.media_type == 'multipart/form-data' || body =~ /[^[:print:]]/
    body = Base64.encode64(body)
  end

  env_headers = get_headers

  # Return all request headers like
  #   ECHO_<foo>: <bar> as a response header <foo>: <bar>
  #   ECHO_<baz>        as a response header <baz>:
  env_headers.select do |k, _v|
    k.start_with? 'HTTP_ECHO_'
  end.each do |header, value|
    response_header = header[ECHO_HEADER_PREFIX_SIZE..-1]
                      .split('_')
                      .map(&:capitalize)
                      .join('-')

    headers[response_header] = value
  end

  response_args = {
    method: request.request_method,
    path: request.path,
    args: request.query_string,
    body: body,
    headers: env_headers,
    uuid: SecureRandom.uuid
  }
  unless body.empty?
    response_args[:bodySha1] = hash
    response_args[:bodyLength] = body.length
  end

  # Prefer JSON if possible, including cases of unrecognised/erroneous types.
  if request.accept?('application/xml') && !request.accept?('application/json')
    content_type 'application/xml'
    build_xml_response(response_args)
  else
    content_type 'application/json'
    JSON.pretty_generate(response_args)
  end
end

def build_xml_response(method:, path:, uuid:, body:, bodySha1: nil,
                       bodyLength: 0, headers:, args: nil)

  builder = Nokogiri::XML::Builder.new do |xml|
    xml.echoResponse do
      xml.method_ method
      xml.path path
      xml.uuid uuid
      xml.bodySha1 bodySha1 if bodySha1
      xml.bodyLength bodyLength if bodyLength > 0
      xml.body body if bodyLength > 0
      xml.headers do |headers_|
        headers.each_pair do |key, value|
          headers_.header do |header|
            header.key key.split('HTTP_')[1]
            header.value value
          end
        end
      end
      xml.args do |args|
        request.env['rack.request.query_hash'].each_pair do |key, value|
          args.arg do |arg|
            arg.key key
            arg.value value
          end
        end
      end
    end
  end
  builder.to_xml
end

get '/status/:code' do |code|
  [code.to_i, echo_response]
end

get '/favicon.ico' do # Avoid bumping counter on favicon
end

all_methods '/**' do
  echo_response
end
