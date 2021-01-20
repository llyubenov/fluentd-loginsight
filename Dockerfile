FROM photon:latest

USER root

# Distro sync and install components
RUN tdnf distro-sync --refresh -y \
    && tdnf install -y \
    rubygem-fluentd \
    rubygem-oj \
    rubygem-async-http \
    jemalloc \
    rubygem-fluent-plugin-vmware-loginsight \
    rubygem-fluent-plugin-kubernetes_metadata_filter

RUN ln -s /usr/lib/ruby/gems/2.5.0/bin/fluentd /usr/bin/fluentd \
    && fluentd --setup

# Make sure fluentd picks jemalloc
ENV LD_PRELOAD="/usr/lib/libjemalloc.so.2"

# Standard fluentd ports
EXPOSE 24224 5140

ENTRYPOINT ["/usr/bin/fluentd"]
