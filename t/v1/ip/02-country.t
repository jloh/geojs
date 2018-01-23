use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

our $HttpConfig = qq{
    geoip_country "$pwd/download-cache/maxmind/GeoIPv6.dat";
    geoip_city "$pwd/download-cache/maxmind/GeoLiteCityv6.dat";
    geoip_org "$pwd/download-cache/maxmind/GeoIPASNumv6.dat";
    lua_package_path "$pwd/lib/?.lua;;";
    real_ip_header X-IP;
    set_real_ip_from  127.0.0.1/32;
};

run_tests();

__DATA__
=== TEST 1: Valid config
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
    location /sanity {
        echo "OK";
    }
--- request
GET /sanity
--- no_error_log
[error]
--- response_body
OK


=== TEST 2: Plain text endpoint
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


=== TEST 3: JSON Endpoint
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
{"country_3":"USA","ip":"8.8.8.8","country":"US","name":"United States"}


=== TEST 4: JS Endpoint
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
countryip({"country_3":"USA","ip":"8.8.8.8","country":"US","name":"United States"})


=== TEST 5: JS Endpoint with custom callback
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
tests({"country_3":"USA","ip":"8.8.8.8","country":"US","name":"United States"})


=== TEST 6: JS Endpoint sanitise user input
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
%3Cscript%3E({"country_3":"USA","ip":"8.8.8.8","country":"US","name":"United States"})
