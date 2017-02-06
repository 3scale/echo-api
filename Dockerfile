FROM centos/ruby-23-centos7 
MAINTAINER Daniel Cesario <dcesario@redhat.com>

RUN yum -y update \
	&& yum -y install openssl-devel 

WORKDIR /opt/echo-api/

COPY ./ /opt/echo-api

RUN chown -fR 1001:1001 /opt/echo-api
USER 1001

ENV BUNDLE_WITHOUT=development:test
RUN bundle install --deployment 

ENTRYPOINT ["bundle", "exec"]
CMD ["rackup", "config.ru"]

#Expose 9292 port
EXPOSE 9292
