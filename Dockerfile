FROM quay.io/3scale/ruby:2.1
MAINTAINER Oriol Martí <oriol@3scale.net> # 2015-06-26

RUN apt-install -y libssl-dev

WORKDIR /opt/echo-api

COPY Gemfile /opt/echo-api/
COPY Gemfile.lock /opt/echo-api/

RUN chown -fR ruby:ruby /opt/echo-api
USER ruby

RUN bundle install --deployment --without development test

COPY config /opt/echo-api/config
COPY config.ru /opt/echo-api/config.ru
COPY echo_api.rb /opt/echo-api/echo_api.rb
USER root

USER ruby
ENTRYPOINT ["bundle", "exec"]
CMD ["/opt/echo-api/vendor/bundle/ruby/2.1.0/bin/rackup", "config.ru"]
#Expose 9292 port
EXPOSE 9292
