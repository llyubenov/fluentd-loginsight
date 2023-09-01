FROM public.ecr.aws/docker/library/photon:4.0-20230826

USER root

ARG RVM_PATH=/usr/local/rvm
ARG RUBY_VERSION=ruby-3.1.4
ARG RUBY_PATH=/usr/local/rvm/rubies/$RUBY_VERSION
ARG RUBYOPT='-W:no-deprecated -W:no-experimental'

ENV PATH $RUBY_PATH/bin:$PATH
ENV FLUENTD_DISABLE_BUNDLER_INJECTION 1
ENV BUILDDEPS="\
      gmp-devel \
      libffi-devel \
      bzip2 \
      shadow \
      which \
      wget \
      vim \
      git \
      less \
      tar \
      gzip \
      sed \
      gcc \
      build-essential \
      zlib-devel \
      libedit \
      libedit-devel \
      gdbm \
      gdbm-devel \
      openssl-devel \
      gpg"

RUN tdnf clean all && \
    tdnf upgrade -y && \
    tdnf erase -y toybox && \
    tdnf install -y \
         findutils \
         procps-ng \
         util-linux \
         systemd \
         net-tools && \
    tdnf clean all

COPY Gemfile Gemfile.lock /fluentd/

RUN tdnf install -y $BUILDDEPS \
  && curl -sSL https://rvm.io/mpapis.asc | gpg --import \
  && curl -sSL https://rvm.io/pkuczynski.asc | gpg --import \
  && curl -sSL https://get.rvm.io | bash -s stable \
  && source /etc/profile.d/rvm.sh \
  && rvm autolibs disable \
  && rvm requirements \
  && rvm install --disable-binary $RUBY_VERSION --default \
  && gem update --system --no-document \
  && gem install bundler -v '>= 2.4.15' --default --no-document \
  && rm -rf $RVM_PATH/src $RVM_PATH/examples $RVM_PATH/docs $RVM_PATH/archives \
    $RUBY_PATH/lib/ruby/gems/3.*/cache $RUBY_PATH/lib/ruby/gems/3.*/doc/ \
    /usr/share/doc /root/.bundle/cache \
  && rvm cleanup all \  
  && gem sources --clear-all \
  && gem cleanup \ 
  && tdnf remove -y $BUILDDEPS \
  && tdnf clean all

RUN tdnf install -y $BUILDDEPS \
  && mkdir -p /fluentd/log /fluentd/etc /fluentd/plugins /usr/local/bundle/bin/ \
  && echo 'gem: --no-document' >> /etc/gemrc \
  && bundle config silence_root_warning true \
  && cd /fluentd \
  && bundle install \
  && cd /fluentd \
  && gem specific_install https://github.com/javiercri/fluent-plugin-google-cloud.git \
  && cd /fluentd \
  && gem sources --clear-all \
  && ln -s $(which fluentd) /usr/local/bundle/bin/fluentd \
  && gem cleanup \
  ## Install jemalloc
  && curl -sLo /tmp/jemalloc-5.3.0.tar.bz2 https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 \
  && tar -C /tmp/ -xjvf /tmp/jemalloc-5.3.0.tar.bz2 \
  && cd /tmp/jemalloc-5.3.0 \
  && ./configure && make \
  && mv -v lib/libjemalloc.so* /usr/lib \
  && rm -rf /tmp/* \
  # cleanup build deps
  && tdnf remove -y $BUILDDEPS \
  && tdnf clean all

# RUN buildDeps="\
#     binutils linux-api-headers glibc-devel \
#     make gcc gmp-devel libffi-devel \
#     tar bzip2 sed gawk build-essential" \
#     #
#     # Distro sync and install build dependencies
#     && tdnf distro-sync --refresh -y \
#     && tdnf remove -y toybox \
#     && tdnf install -y $buildDeps ruby \
#     #
#     # These are not required but are used if available
#     && gem install oj -v 3.13.23 \
#     && gem install ffi \
#     && gem install gelf -v 3.1.0 \
#     && gem install logfmt -v 0.0.10 \
#     && gem install kubeclient -v '~> 4.9.3' \
#     && gem install gssapi -v 1.3.1 \
#     && gem install specific_install -v 0.3.8 \
#     && gem install json -v 2.2.0 \
#     && gem install async-http -v 0.46.3 \
#     #
#     # Install fluentd
#     && gem install --norc --no-document fluentd -v 1.16.1 \
#     && gem install --norc --no-document fluent-plugin-multi-format-parser -v '~> 1.0.0'\
#     && gem install --norc --no-document fluent-plugin-concat -v '~> 2.5.0'\
#     && gem install --norc --no-document fluent-plugin-grok-parser -v '~> 2.6.2' \
#     && gem install --norc --no-document fluent-plugin-json-in-json-2 -v '>= 1.0.2' \
#     && gem install --norc --no-document fluent-plugin-rewrite-tag-filter -v '~> 2.4.0' \
#     && gem install --norc --no-document fluent-plugin-parser-cri -v '~> 0.1.0' \
#     && gem install --norc --no-document fluent-plugin-cloudwatch-logs -v '~> 0.14.3' \
#     && gem install --norc --no-document fluent-plugin-kubernetes -v 0.3.1 \
#     && gem install --norc --no-document fluent-plugin-kubernetes_metadata_filter -v '~> 3.2.0' \
#     && gem install --norc --no-document fluent-plugin-papertrail -v 0.2.8 \
#     && gem install --norc --no-document fluent-plugin-prometheus -v 2.1.0 \
#     && gem install --norc --no-document fluent-plugin-record-modifier -v 2.1.0 \
#     && gem install --norc --no-document fluent-plugin-record-reformer - 0.9.1 \
#     && gem install --norc --no-document fluent-plugin-systemd -v '~> 1.0.5'\
#     && gem install --norc --no-document fluent-plugin-systemd \
#     && gem install --norc --no-document fluent-plugin-uri-parser -v 0.3.0 \
#     && gem install --norc --no-document fluent-plugin-mysqlslowquery -v 0.0.9 \
#     && gem install --norc --no-document fluent-plugin-throttle -v 0.0.5 \
#     && gem install --norc --no-document fluent-plugin-webhdfs -v 1.5.0 \
#     && gem install --norc --no-document i18n \
#     && gem install --norc --no-document fluent-plugin-remote_syslog -v 1.0.0 \
#     && gem install --norc --no-document fluent-plugin-detect-exceptions -v '~> 0.0.15'\
#     #
#     # Install Log Insight plugin
#     && gem install --norc --no-document fluent-plugin-vmware-loginsight -v 1.4.1\
#     # Install Log Intelligence plugin
#     && gem install --norc --no-document fluent-plugin-vmware-log-intelligence -v 2.0.8 \
#     #
#     # Install jemalloc 5.3.0
#     && curl -L --output /tmp/jemalloc-5.3.0.tar.bz2 https://github.com/jemalloc/jemalloc/releases/download/5.3.0/jemalloc-5.3.0.tar.bz2 \
#     && tar -C /tmp/ -xjvf /tmp/jemalloc-5.3.0.tar.bz2 \
#     && cd /tmp/jemalloc-5.3.0 \
#     && ./configure && make \
#     && mv lib/libjemalloc.so.2 /usr/lib \
#     && cd / \
#     && rm -rf /tmp/jemalloc-5.3.0* \
#     && tdnf remove -y $buildDeps \
#     && tdnf clean all \
#     && gem sources --clear-all \
#     && gem cleanup

# Make sure fluentd picks jemalloc
ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"

# Standard fluentd ports
EXPOSE 24224 5140

# Copy plugins
COPY plugins /fluentd/plugins/
COPY entrypoint.sh /fluentd/entrypoint.sh

# Environment variables
ENV FLUENTD_OPT=""
ENV FLUENTD_CONF="fluent.conf"

# Overwrite ENTRYPOINT to run fluentd as root for /var/log / /var/lib
ENTRYPOINT ["tini",  "--", "/bin/entrypoint.sh"]


# COPY Gemfile* /fluentd/
# RUN buildDeps="sudo make gcc g++ libc-dev libffi-dev" \
#   runtimeDeps="" \
#   && apt-get update \
#   #&& apt-get upgrade -y \
#   && apt-get install \
#      -y --no-install-recommends \
#      $buildDeps $runtimeDeps net-tools \
#   && gem install bundler \
#   && bundle config silence_root_warning true \
#   && bundle install --gemfile=/fluentd/Gemfile \ 
#      --path=/fluentd/vendor/bundle \
#   && SUDO_FORCE_REMOVE=yes \
#      apt-get purge -y --auto-remove \
#                   -o APT::AutoRemove::RecommendsImportant=false \
#                   $buildDeps \
#   && rm -rf /var/lib/apt/lists/* \
#   && gem sources --clear-all \
#   && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem
# RUN touch /fluentd/etc/disable.conf

# # Copy plugins
# COPY plugins /fluentd/plugins/
# COPY entrypoint.sh /fluentd/entrypoint.sh

# # Environment variables
# ENV FLUENTD_OPT=""
# ENV FLUENTD_CONF="fluent.conf"

# # Overwrite ENTRYPOINT to run fluentd as root for /var/log / /var/lib
# ENTRYPOINT ["tini",  "--", "/bin/entrypoint.sh"]