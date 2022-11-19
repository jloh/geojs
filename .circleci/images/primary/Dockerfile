FROM openresty/openresty:1.21.4.1-3-jammy

RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:maxmind/ppa
RUN apt-get update && apt-get install -y cpanminus libgd-dev git luarocks geoipupdate libmaxminddb0 libmaxminddb-dev
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive TAP::Formatter::JUnit
RUN apt-get autoremove -y make
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN opm install ledgetech/lua-resty-http=0.16.1
RUN opm install openresty/lua-resty-dns=0.21
RUN opm install openresty/lua-resty-upload=0.10
RUN opm install bungle/lua-resty-reqargs=1.4
RUN opm install xiaooloong/lua-resty-iconv=0.2.0
RUN opm install anjia0532/lua-resty-maxminddb=1.3.3
# luacov is broken currently :()
#RUN luarocks install luacov-coveralls --tree=/usr/local/openresty/luajit
