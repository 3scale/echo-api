FROM quay.io/3scale/ruby:2.1
MAINTAINER Oriol Martí <oriol@3scale.net> # 2015-06-26

RUN apt-install -y libssl-dev

WORKDIR /opt/echo-api/

COPY ./ /opt/echo-api

RUN chown -fR ruby:ruby /opt/echo-api
USER ruby

RUN bundle install --deployment --without development test

ENTRYPOINT ["bundle", "exec"]
CMD ["rackup", "config.ru", "--host", "0.0.0.0"]
EXPOSE 9292
