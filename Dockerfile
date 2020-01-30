# Common base image
FROM registry.access.redhat.com/ubi8/ubi-minimal AS base

EXPOSE 9292

ENV HOME=/home
WORKDIR "${HOME}/app"

ARG RUBY_VERSION="2.6"
ARG BUNDLER_VERSION="2.1.4"
ARG RUNTIME_DEPS="ruby"

# TODO: microdnf currently contains a nasty bug in which using --nodocs or --setopt=tsflags=nodocs fails
RUN echo -e "[ruby]\nname=ruby\nstream=${RUBY_VERSION}\nprofiles=\nstate=enabled\n" > /etc/dnf/modules.d/ruby.module \
  && microdnf update \
  && microdnf install ${RUNTIME_DEPS} \
  && gem install -N bundler -v "= ${BUNDLER_VERSION}" \
  && chown -R 1001:1001 "${HOME}"

# Build image without source code (useful for dev image)
FROM base AS builder-base

ARG BUILD_DEPS="tar make file findutils git patch gcc automake autoconf libtool redhat-rpm-config openssl-devel ruby-devel"

RUN microdnf install ${BUILD_DEPS}

COPY --chown=1001:1001 ./Gemfile* "${HOME}/app/"

USER 1001:1001

FROM builder-base AS builder-with-gems
RUN bundle config --global without 'test development' \
  && bundle config --global deployment 'true' \
  && bundle install

# Build image with source code
FROM builder-with-gems AS builder

# Copy sources
COPY --chown=1001:1001 ./ "${HOME}/app/"

# Runtime image
FROM base AS production
MAINTAINER Alejandro Martinez Ruiz <amr@redhat.com>

USER 1001:1001

# Copy over the whole bundle
COPY --chown=1001:1001 --from=builder "${HOME}/" "${HOME}/"

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0"]

# Development image
FROM builder-base AS dev

USER root

ARG DEV_TOOLS="vim gdb"
RUN microdnf install ${DEV_TOOLS}

ARG DEV_UID=1001
ARG DEV_GID=1001
ENV DEV_UID=${DEV_UID} DEV_GID=${DEV_GID} PATH="${PATH}:${HOME}/bin"

RUN chown -R ${DEV_UID}:${DEV_GID} "${HOME}"

USER ${DEV_UID}:${DEV_GID}

RUN bundle config --global with 'test development' \
  && bundle config --global silence_root_warning 1 \
  && bundle config --global bin "${HOME}/bin" \
  && bundle config --global path "${HOME}/gems" \
  && bundle install

CMD ["/bin/bash"]

