FROM openresty/openresty:1.21.4.1-3-jammy

RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:maxmind/ppa
RUN apt-get update && apt-get install -y cpanminus libgd-dev git luarocks geoipupdate libmaxminddb0 libmaxminddb-dev
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive TAP::Formatter::JUnit
RUN apt-get autoremove -y
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
# luacov is broken currently :()
#RUN luarocks install luacov-coveralls --tree=/usr/local/openresty/luajit
