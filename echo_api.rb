#shotgun app.rb -p 9294

require 'sinatra'
require "json"

require 'async-rack'
require 'sinatra/async'
register Sinatra::Async

enable :logging

def all_methods(path, opts = {}, &block)
  aget(path, opts, &block)
  apost(path, opts, &block)
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
  res = {
    method: request.request_method,
    path: request.path,
    args: request.query_string,
    body: request.body.read,
    headers: get_headers()
  }.to_json

  body(res)
end
