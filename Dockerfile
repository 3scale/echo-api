FROM centos:7 
LABEL authors="Oriol Martí <oriol@3scale.net>,Daniel Cesario <dcesario@redhat.com>"

ENV RUBY_VERSION="rh-ruby23"

RUN yum -y update \
  && yum install -y centos-release-scl \
  && yum install -y \
    gcc \
    make \ 
    openssl-devel \
    ${RUBY_VERSION} \
    ${RUBY_VERSION}-ruby-devel \
  && yum clean all

WORKDIR /opt/echo-api/

COPY ./ /opt/echo-api
COPY contrib/scl_enable /opt/echo-api/etc/

RUN source /opt/echo-api/etc/scl_enable \
  && gem install -N bundler \
  && gem env \
  && bundle config --global silence_root_warning 1 

ENV BASH_ENV=/opt/echo-api/etc/scl_enable \
    ENV=/opt/echo-api/etc/scl_enable \
    PROMPT_COMMAND=". /opt/echo-api/etc/scl_enable" \
  BUNDLE_WITHOUT=development:test

RUN source /opt/echo-api/etc/scl_enable \
  && bundle install --deployment 

EXPOSE 9292

USER 1001
ENTRYPOINT ["/opt/echo-api/entrypoint.sh"]
CMD ["rackup", "config.ru", "-o", "0.0.0.0"]
