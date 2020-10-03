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
=== TEST 1.a: Plain text endpoint
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


=== TEST 1.b: Plain text endpoint with specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: text/plain
--- response_body
US


=== TEST 2.a: JSON Endpoint
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
{"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"}


=== TEST 2.b: JSON Endpoint with specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8.json
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body
{"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"}


=== TEST 3.a: JS Endpoint
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
countryip({"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"})


=== TEST 3.b: JS Endpoint with specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8.js
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
countryip({"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"})


=== TEST 4.a: JS Endpoint with custom callback
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
tests({"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"})


=== TEST 4.b: JS Endpoint with custom callback specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8.js?callback=tests
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
tests({"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"})


=== TEST 5.a: JS Endpoint sanitise user input
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
%3Cscript%3E({"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"})


=== TEST 5.b: JS Endpoint sanitise user input specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8.js?callback=<script>
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
%3Cscript%3E({"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"})


=== TEST 6.a: Full plain text endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/full
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: text/plain
--- response_body
United States


=== TEST 6.b: Full plain text endpoint with specific IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/full/8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: text/plain
--- response_body
United States
