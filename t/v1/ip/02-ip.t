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
GET /v1/ip
--- no_error_log
[error]
--- response_headers
Content-Type: text/plain
--- response_body
127.0.0.1


=== TEST 2: JSON Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip.json
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body
{"ip":"127.0.0.1"}


=== TEST 3: JS Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip.js
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
geoip({"ip":"127.0.0.1"})


=== TEST 4: JS Endpoint with custom callback
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip.js?callback=tests
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
tests({"ip":"127.0.0.1"})


=== TEST 5: JS Endpoint sanitise user input
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip.js?callback=<script>
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
%3Cscript%3E({"ip":"127.0.0.1"})
