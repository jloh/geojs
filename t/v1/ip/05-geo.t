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

no_long_string();
no_diff();
run_tests();

__DATA__
=== TEST 1.b: JSON Endpoint
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
{"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"}


=== TEST 1.b: JSON Endpoint specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo/8.8.8.8.json
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body
{"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"}


=== TEST 2.a: JS Endpoint
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
geoip({"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"})


=== TEST 2.b: JS Endpoint specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo/8.8.8.8.js
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
geoip({"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"})


=== TEST 3.a: JS Endpoint with custom callback
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
tests({"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"})


=== TEST 3.b: JS Endpoint with custom callback specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo/8.8.8.8.js?callback=tests
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
tests({"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"})


=== TEST 4.a: JS Endpoint sanitise user input
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
%3Cscript%3E({"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"})


=== TEST 4.b: JS Endpoint sanitise user input
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo/8.8.8.8.js?callback=<script>
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
%3Cscript%3E({"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"})


=== TEST 5: JSON Endpoint with private IP via query param does not error
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.json?ip=10.10.123.190
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body_like eval
qr/"ip":"10\.10\.123\.190"/


=== TEST 6: JSON Endpoint with loopback IP via query param does not error
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.json?ip=127.0.0.1
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body_like eval
qr/"ip":"127\.0\.0\.1"/


=== TEST 7: JSON Endpoint with 172.x private IP via query param does not error
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.json?ip=172.19.129.140
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body_like eval
qr/"ip":"172\.19\.129\.140"/


=== TEST 8: JS Endpoint with private IP via query param does not error
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.js?ip=192.168.1.1
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body_like eval
qr/"ip":"192\.168\.1\.1"/


=== TEST 9: JSON Endpoint with multiple IPs including private does not error
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.json?ip=8.8.8.8,10.0.0.1,192.168.1.1
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body_like eval
qr/"ip":"10\.0\.0\.1"/
