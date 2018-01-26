FROM ubuntu:xenial

RUN apt-get update && apt-get install -y lua-cjson nginx-extras cpanminus libluajit-5.1-dev libgd-dev git luarocks
RUN cpanm -v --notest Test::Nginx TAP::Harness::Archive
RUN luarocks install luacov-coveralls
