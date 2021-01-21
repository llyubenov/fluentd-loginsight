# Fluentd plugin for VMware Log Insight
# 
# Copyright 2018-2019 VMware, Inc. All Rights Reserved. 
# 
# This product is licensed to you under the MIT license (the "License").  You may not use this product except in compliance with the MIT License.  
# 
# This product may include a number of subcomponents with separate copyright notices and license terms. Your use of these subcomponents is subject to the terms and conditions of the subcomponent's license, as noted in the LICENSE file. 
# 
# SPDX-License-Identifier: MIT


# Sample Dockerfile to use as log collector
# Builds a debian-based fluentd image that has fluent-plugin-kubernetes_metadata_filter,
# fluent-plugin-rewrite-tag-filter, fluent-plugin-systemd and
# fluent-plugin-vmware-loginsight gem installed.
#
# This image will get preconfigured with the fluent.conf if avaialble at the
# same dir level. For fluentd config example, see
# https://github.com/vmware/fluent-plugin-vmware-loginsight/blob/master/examples/fluent.conf

# This base image is built from https://github.com/fluent/fluentd-kubernetes-daemonset
# FROM fluent/fluentd:v1.11-debian-1

# # Use root account to use apt
# USER root

# WORKDIR /home/fluent
# ENV PATH /fluentd/vendor/bundle/ruby/2.6.0/bin:$PATH
# ENV GEM_PATH /fluentd/vendor/bundle/ruby/2.6.0
# ENV GEM_HOME /fluentd/vendor/bundle/ruby/2.6.0
# # skip runtime bundler installation
# ENV FLUENTD_DISABLE_BUNDLER_INJECTION 1

# COPY Gemfile* /fluentd/
# You can install your plugins here
# RUN buildDeps="sudo make gcc g++ libc-dev" \
#  && apt-get update \
#  && apt-get install -y --no-install-recommends $buildDeps \
#  && sudo gem install \
#         fluent-plugin-kubernetes_metadata_filter:2.4.6 \
#         fluent-plugin-rewrite-tag-filter:2.3.0 \
#         fluent-plugin-systemd:1.0.2 \
#         fluent-plugin-vmware-loginsight:0.1.10 \
#  && sudo gem sources --clear-all \
#  && SUDO_FORCE_REMOVE=yes \
#     apt-get purge -y --auto-remove \
#                   -o APT::AutoRemove::RecommendsImportant=false \
#                   $buildDeps \
#  && rm -rf /var/lib/apt/lists/* \
#  && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem


FROM fluent/fluentd:v1.11.5-debian-1.0

USER root
WORKDIR /home/fluent
ENV PATH /fluentd/vendor/bundle/ruby/2.6.0/bin:$PATH
ENV GEM_PATH /fluentd/vendor/bundle/ruby/2.6.0
ENV GEM_HOME /fluentd/vendor/bundle/ruby/2.6.0
# skip runtime bundler installation
ENV FLUENTD_DISABLE_BUNDLER_INJECTION 1

COPY Gemfile* /fluentd/
RUN buildDeps="sudo make gcc g++ libc-dev libffi-dev" \
  runtimeDeps="" \
      && apt-get update \
     && apt-get upgrade -y \
     && apt-get install \
     -y --no-install-recommends \
     $buildDeps $runtimeDeps net-tools \
    && gem install bundler --version 2.1.4 \
    && bundle config silence_root_warning true \
    && bundle install --gemfile=/fluentd/Gemfile --path=/fluentd/vendor/bundle \
    && SUDO_FORCE_REMOVE=yes \
    apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
                  $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
    && gem sources --clear-all \
    && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem
# Copy configuration files
# COPY ./conf/fluent.conf /fluentd/etc/
# COPY ./conf/systemd.conf /fluentd/etc/
# COPY ./conf/kubernetes.conf /fluentd/etc/
# COPY ./conf/prometheus.conf /fluentd/etc/
RUN touch /fluentd/etc/disable.conf

# Copy plugins
COPY plugins /fluentd/plugins/

#  You can install the LI plugin using a gem or if you want to test your
#  changes to plugin, you may add the .rb directly under `plugins` dir, then
#  you don't need to install the gem
#COPY plugins /fluentd/plugins/
