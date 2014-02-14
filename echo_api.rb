#shotgun app.rb -p 9294

require 'sinatra'
require "json"

require 'newrelic_rpm'

enable :logging

configure { set :server, :puma }

require 'securerandom'

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

@@random = Random.new
@@random_files = Hash.new{|hash,size| hash[size] = @@random.bytes(size) }

get '/size/:size' do |size|
  size, unit = size.scan(/\d+|\D+/)

  size = Integer(size)
  unit = String(unit).downcase

  multiplier = case unit
                 when 'kb' then 1024
                 when 'mb' then 1024*1024
                 else 1
               end

  content_type 'application/octet-stream'
  body @@random_files[size * multiplier]
end


get '/wait/:seconds' do |seconds|
  duration = Float(seconds)
  stream do |io|
    increment = duration / 1000
    1000.times do |i|
      Kernel.sleep(increment)
      io << "waited for #{increment}s\n"
    end

    io << "done waiting #{duration}"
  end
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
