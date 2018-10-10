FROM openresty/openresty:1.13.6.2-xenial

RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:maxmind/ppa
RUN apt-get update && apt-get install -y lua-cjson cpanminus libluajit-5.1-dev libgd-dev git luarocks geoipupdate libmaxminddb0 libmaxminddb-dev mmdb-bin
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive
RUN luarocks install luacov-coveralls
