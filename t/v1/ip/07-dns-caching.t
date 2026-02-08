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
=== TEST 1: /v1/dns/ptr (no IP param) should NOT be cacheable
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
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 2: /v1/dns/ptr/{IP} should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr/8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 3: /v1/dns/ptr?ip=X should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 4: /v1/dns/ptr.json (no IP param) should NOT be cacheable
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
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 5: /v1/dns/ptr/{IP}.json should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr/8.8.8.8.json
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 6: /v1/dns/ptr.json?ip=X should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr.json?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 7: /v1/dns/ptr.js (no IP param) should NOT be cacheable
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
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 8: /v1/dns/ptr/{IP}.js should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr/8.8.8.8.js
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 9: /v1/dns/ptr.js?ip=X should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/dns.conf";
    set $geojs_dns_server '8.8.8.8';
--- request
GET /v1/dns/ptr.js?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000

