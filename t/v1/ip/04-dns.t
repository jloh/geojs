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
=== TEST 1: Valid config
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    location /sanity {
        echo "OK";
    }
--- request
GET /sanity
--- no_error_log
[error]
--- response_body
OK


=== TEST 2.a: Plain text endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: text/plain
--- response_body
google-public-dns-a.google.com


=== TEST 2.b: Plain text endpoint IP arg
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr?ip=8.8.4.4
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: text/plain
--- response_body
google-public-dns-b.google.com


=== TEST 3.a: JSON Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr.json
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body
{"ptr":"google-public-dns-a.google.com"}


=== TEST 3.b: JSON Endpoint IP arg
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr.json?ip=8.8.4.4
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/json
--- response_body
{"ptr":"google-public-dns-b.google.com"}


=== TEST 4.a: JS Endpoint
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr.js
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
ptr({"ptr":"google-public-dns-a.google.com"})


=== TEST 4.b: JS Endpoint IP arg
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr.js?ip=8.8.4.4
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Content-Type: application/javascript
--- response_body
ptr({"ptr":"google-public-dns-b.google.com"})
