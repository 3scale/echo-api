FROM centos:7 
MAINTAINER Daniel Cesario <dcesario@redhat.com>

USER root

RUN yum -y update && yum install -y \
	centos-release-scl \
	gcc \
	make \
	openssl-devel \ 
	rh-ruby23 \
	rh-ruby23-ruby-devel 

WORKDIR /opt/echo-api/

COPY ./ /opt/echo-api

COPY contrib/scl_enable /opt/echo-api/etc/

RUN chown -fR 1001:1001 /opt/echo-api

RUN	source /opt/echo-api/etc/scl_enable \
	&& gem install -N bundler \
	&& gem env \
	&& bundle config --global silence_root_warning 1 \

USER 1001

ENV BASH_ENV=/opt/echo-api/etc/scl_enable \
    ENV=/opt/echo-api/etc/scl_enable \
    PROMPT_COMMAND=". /opt/echo-api/etc/scl_enable" \
	BUNDLE_WITHOUT=development:test

RUN source /opt/echo-api/etc/scl_enable \
	&& bundle install --deployment 

EXPOSE 9292

ENTRYPOINT ["/opt/echo-api/entrypoint.sh"]
CMD ["rackup", "config.ru", "-o", "0.0.0.0"]
