use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

$ENV{TEST_COVERAGE} ||= 0;

our $HttpConfig = qq{
    init_by_lua_block {
        if $ENV{TEST_COVERAGE} == 1 then
            require("luacov.runner").init()
        end
    }
    geoip_country "$pwd/download-cache/maxmind/GeoIPv6.dat";
    geoip_city "$pwd/download-cache/maxmind/GeoLiteCityv6.dat";
    geoip_org "$pwd/download-cache/maxmind/GeoIPASNumv6.dat";
    lua_package_path "$pwd/lib/?.lua;$pwd/repos/lua-resty-iconv/lualib/?.lua;;";
    real_ip_header X-IP;
    set_real_ip_from  127.0.0.1/32;
};

run_tests();

__DATA__
=== TEST 1: JSON Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.json
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body
{"latitude":"37.7510","organization":"AS15169 Google LLC","country_code":"US","ip":"8.8.8.8","longitude":"-97.8220","area_code":"0","continent_code":"NA","country":"United States","country_code3":"USA"}


=== TEST 2: JS Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- more_headers
X-IP: 8.8.8.8
--- request
GET /v1/ip/geo.js
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
geoip({"latitude":"37.7510","organization":"AS15169 Google LLC","country_code":"US","ip":"8.8.8.8","longitude":"-97.8220","area_code":"0","continent_code":"NA","country":"United States","country_code3":"USA"})


=== TEST 3: JS Endpoint with custom callback
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.js?callback=tests
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
tests({"latitude":"37.7510","organization":"AS15169 Google LLC","country_code":"US","ip":"8.8.8.8","longitude":"-97.8220","area_code":"0","continent_code":"NA","country":"United States","country_code3":"USA"})


=== TEST 4: JS Endpoint sanitise user input
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.js?callback=<script>
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
%3Cscript%3E({"latitude":"37.7510","organization":"AS15169 Google LLC","country_code":"US","ip":"8.8.8.8","longitude":"-97.8220","area_code":"0","continent_code":"NA","country":"United States","country_code3":"USA"})
