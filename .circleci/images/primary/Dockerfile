FROM openresty/openresty:1.13.6.2-xenial

RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:maxmind/ppa
RUN apt-get update && apt-get install -y cpanminus libgd-dev git luarocks geoipupdate libmaxminddb0 libmaxminddb-dev
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive TAP::Formatter::JUnit
# luacov is broken currently :()
#RUN luarocks install luacov-coveralls --tree=/usr/local/openresty/luajit
