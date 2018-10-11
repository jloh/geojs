FROM ubuntu:xenial

RUN apt-get update && apt-get install -y software-properties-common wget
RUN apt-add-repository ppa:maxmind/ppa
RUN wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
RUN apt-get update && apt-get install -y cpanminus libgd-dev git luarocks geoipupdate libmaxminddb0 libmaxminddb-dev mmdb-bin openresty
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive TAP::Formatter::JUnit
RUN luarocks install luacov-coveralls --tree=/usr/local/openresty/luajit
RUN luarocks install luacov-cobertura --tree=/usr/local/openresty/luajit
