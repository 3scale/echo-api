#shotgun app.rb -p 9294

require 'sinatra'
require 'json'
require 'nokogiri'
require 'digest/sha1'
require 'securerandom'
require 'base64'

@@random = Random.new

enable :logging

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

def get_echoable_headers
  get_headers().select {|k, v| k.start_with? 'HTTP_ECHO_'}
end

def echo_response
  body = request.body.read
  hash = Digest::SHA1.base64digest(body)
  # B64 encode if contains obviously non-printable character(s).
  if request.media_type == 'application/octet-stream' ||
      request.media_type == 'multipart/form-data' || body =~ /[^[:print:]]/
    body = Base64.encode64(body)
  end

  # Return all request headers like
  #   ECHO_<foo>: <bar> as a response header <foo>: <bar>
  #   ECHO_<baz>        as a response header <baz>:
  get_echoable_headers.each do |(header, value)|
    response_header = header
                        .gsub(/HTTP_ECHO_/, '')
                        .split('_')
                        .collect(&:capitalize)
                        .join('-')

    headers[response_header] = value
  end

  response_args = {
    method: request.request_method,
    path: request.path,
    args: request.query_string,
    body: body,
    headers: get_headers(),
    uuid: SecureRandom.uuid
  }
  response_args.merge!(
    bodySha1: hash,
    bodyLength: body.length
  ) if body.length > 0

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
  bodyLength:0, headers:, args: nil)

  builder = Nokogiri::XML::Builder.new do |xml|
    xml.echoResponse {
      xml.method_ method
      xml.path path
      xml.uuid uuid
      xml.bodySha1 bodySha1 if bodySha1
      xml.bodyLength bodyLength if bodyLength > 0
      xml.body body if bodyLength > 0
      xml.headers { |headers_|
        headers.each_pair do |key, value|
          headers_.header { |header|
            header.key key.split('HTTP_')[1]
            header.value value
          }
        end
      }
      xml.args { |args|
        request.env['rack.request.query_hash'].each_pair do |key, value|
          args.arg { |arg|
            arg.key key
            arg.value value
          }
        end
      }
    }
  end
  builder.to_xml
end

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

get '/favicon.ico' do # Avoid bumping counter on favicon
end

all_methods "/**" do
  echo_response
end
