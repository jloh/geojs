FROM ubuntu:xenial

RUN apt-get update && apt-get install -y software-properties-common
RUN apt-add-repository ppa:maxmind/ppa
RUN apt-get update && apt-get install -y lua-cjson nginx-extras cpanminus libluajit-5.1-dev libgd-dev git luarocks geoipupdate
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive
RUN luarocks install luacov-coveralls
