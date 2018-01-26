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
    lua_package_path "$pwd/lib/?.lua;;";
    real_ip_header X-IP;
    set_real_ip_from  127.0.0.1/32;
};

run_tests();

__DATA__
=== TEST 1: Plain text endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: text/plain
--- response_body
US


=== TEST 2: JSON Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country.json
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body
{"country":"US","ip":"8.8.8.8","name":"United States","country_3":"USA"}


=== TEST 3: JS Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- more_headers
X-IP: 8.8.8.8
--- request
GET /v1/ip/country.js
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
countryip({"country":"US","ip":"8.8.8.8","name":"United States","country_3":"USA"})


=== TEST 4: JS Endpoint with custom callback
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country.js?callback=tests
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
tests({"country":"US","ip":"8.8.8.8","name":"United States","country_3":"USA"})


=== TEST 5: JS Endpoint sanitise user input
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country.js?callback=<script>
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
%3Cscript%3E({"country":"US","ip":"8.8.8.8","name":"United States","country_3":"USA"})
