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
    lua_package_path "$pwd/lib/?.lua;;";
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
{"organization_name":"Google LLC","accuracy":1000,"asn":15169,"organization":"AS15169 Google LLC","longitude":"-97.822","country_code3":"USA","area_code":"0","ip":"8.8.8.8","country":"United States","continent_code":"NA","country_code":"US","latitude":"37.751"}


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
geoip({"organization_name":"Google LLC","accuracy":1000,"asn":15169,"organization":"AS15169 Google LLC","longitude":"-97.822","country_code3":"USA","area_code":"0","ip":"8.8.8.8","country":"United States","continent_code":"NA","country_code":"US","latitude":"37.751"})


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
tests({"organization_name":"Google LLC","accuracy":1000,"asn":15169,"organization":"AS15169 Google LLC","longitude":"-97.822","country_code3":"USA","area_code":"0","ip":"8.8.8.8","country":"United States","continent_code":"NA","country_code":"US","latitude":"37.751"})


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
%3Cscript%3E({"organization_name":"Google LLC","accuracy":1000,"asn":15169,"organization":"AS15169 Google LLC","longitude":"-97.822","country_code3":"USA","area_code":"0","ip":"8.8.8.8","country":"United States","continent_code":"NA","country_code":"US","latitude":"37.751"})
