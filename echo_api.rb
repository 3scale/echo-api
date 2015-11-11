#shotgun app.rb -p 9294

require 'sinatra'
require "json"

require 'newrelic_rpm'

enable :logging
set :protection, except: [:json_csrf]

configure do
  set :server, :puma
  set :public_folder, 'tmp'
  enable :static
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
  env.select {|k, v| k.start_with? 'HTTP_'}
end

def echo_response
  request.body.rewind

  content_type 'application/json'
  JSON.pretty_generate(
    method: request.request_method,
    path: request.path,
    args: request.query_string,
    body: request.body.read,
    headers: get_headers()
  )
end

@@random = Random.new

def random_file(name, size)
  path = Pathname.new('tmp').join('size', name)

  return path if path.exist?

  content = @@random.bytes(size)
  path.dirname.mkpath

  path.open('w') do |f|
    f << content
  end

  path
end


get '/size/:size' do |original_size|
  size, unit = original_size.scan(/\d+|\D+/)

  size = Integer(size)
  unit = String(unit).downcase

  multiplier = case unit
                 when 'kb' then 1024
                 when 'mb' then 1024*1024
                 else 1
               end

  send_file random_file(original_size,  * multiplier)
end

get '/status/:code' do |code|
  [code.to_i, echo_response]
end

get '/wait/:seconds' do |seconds|
  duration = Float(seconds)

  Kernel.sleep(duration)
  body "slept #{duration} seconds"
end


all_methods "/**" do
  echo_response
end
