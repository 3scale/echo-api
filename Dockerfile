FROM centos/ruby-23-centos7 
MAINTAINER Daniel Cesario <dcesario@redhat.com>

USER root

RUN yum -y update \
	&& yum -y install openssl-devel 

WORKDIR /opt/echo-api/

COPY ./ /opt/echo-api

RUN chown -fR 1001:1001 /opt/echo-api

USER 1001

COPY contrib/scl_enable /opt/echo-api/etc/

ENV BASH_ENV=/opt/echo-api/etc/scl_enable \
    ENV=/opt/echo-api/etc/scl_enable \
    PROMPT_COMMAND=". /opt/echo-api/etc/scl_enable" \
	BUNDLE_WITHOUT=development:test

RUN source /opt/echo-api/etc/scl_enable \
	&& bundle install --deployment 

EXPOSE 9292

ENTRYPOINT ["/opt/echo-api/entrypoint.sh"]
CMD ["rackup", "config.ru"]
