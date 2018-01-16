#!/usr/bin/env bash

# Download Maxmind DBs
working_dir='/root/project'

mkdir -p $working_dir/download-cache/maxmind

test -s $working_dir/download-cache/maxmind/GeoLiteCityv6.dat ||  curl -s http://geolite.maxmind.com/download/geoip/database/GeoLiteCityv6-beta/GeoLiteCityv6.dat.gz | gzip -dc > $working_dir/download-cache/maxmind/GeoLiteCityv6.dat
test -s $working_dir/download-cache/maxmind/GeoIPv6.dat       ||  curl -s http://geolite.maxmind.com/download/geoip/database/GeoIPv6.dat.gz                          | gzip -dc > $working_dir/download-cache/maxmind/GeoIPv6.dat
test -s $working_dir/download-cache/maxmind/GeoIPASNumv6.dat  ||  curl -s http://download.maxmind.com/download/geoip/database/asnum/GeoIPASNumv6.dat.gz              | gzip -dc > $working_dir/download-cache/maxmind/GeoIPASNumv6.dat
