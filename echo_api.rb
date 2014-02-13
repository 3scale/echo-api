#shotgun app.rb -p 9294

require 'sinatra'
require "json"

require 'newrelic_rpm'

enable :logging

configure { set :server, :puma }

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
  env.select {|k, v| k.start_with? 'HTTP_'}
end

all_methods "/**" do
  r = request.body.rewind

  return {
    method: request.request_method,
    path: request.path,
    args: request.query_string,
    body: request.body.read,
    headers: get_headers()
  }.to_json
end
