# GeoJS Test Environment
# Replicates the CI environment for local testing
FROM openresty/openresty:1.27.1.2-1-bullseye-fat@sha256:1899c4cbca2199cb2dc847e99e81ef2b5ab2345df0db247af2f391ad6f711994

# Install system dependencies
# Note: We don't restrict to amd64 here to support ARM Macs
RUN echo "deb http://deb.debian.org/debian bullseye contrib" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cpanminus \
        libgd-dev \
        libmaxminddb0 \
        libmaxminddb-dev \
        curl \
        geoipupdate \
    && rm -rf /var/lib/apt/lists/*

# Install Perl test dependencies
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive TAP::Formatter::JUnit

# Install OPM packages
RUN opm install ledgetech/lua-resty-http=0.17.1 && \
    opm install openresty/lua-resty-dns=0.23 && \
    opm install openresty/lua-resty-upload=0.10 && \
    opm install bungle/lua-resty-reqargs=1.4 && \
    opm install xiaooloong/lua-resty-iconv=0.2.0 && \
    opm install anjia0532/lua-resty-maxminddb=1.3.7

# Link OpenResty for Test::Nginx discovery
RUN ln -sf /usr/local/openresty/bin/openresty /usr/bin/nginx

# Create directories for MaxMind databases
RUN mkdir -p /var/lib/GeoIP

WORKDIR /opt/geojs

# Default command runs all tests
CMD ["prove", "-r", "t"]
