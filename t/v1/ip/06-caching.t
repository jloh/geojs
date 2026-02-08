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
=== TEST 1: /v1/ip should NOT be cacheable (uses requester IP)
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 2: /v1/ip.json should NOT be cacheable (uses requester IP)
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip.json
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 3: /v1/ip.js should NOT be cacheable (uses requester IP)
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip.js
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 4: /v1/ip/country (no IP param) should NOT be cacheable
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
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 5: /v1/ip/country/{IP} should BE cacheable (explicit IP in path)
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 6: /v1/ip/country?ip=X should BE cacheable (explicit IP in query)
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 7: /v1/ip/country.json (no IP param) should NOT be cacheable
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
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 8: /v1/ip/country/{IP}.json should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8.json
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 9: /v1/ip/country.json?ip=X should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country.json?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 10: /v1/ip/country.js (no IP param) should NOT be cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country.js
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 11: /v1/ip/country/{IP}.js should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/8.8.8.8.js
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 12: /v1/ip/country.js?ip=X should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country.js?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 13: /v1/ip/country/full (no IP param) should NOT be cacheable
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
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 14: /v1/ip/country/full/{IP} should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/country/full/8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 15: /v1/ip/geo.json (no IP param) should NOT be cacheable
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
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 16: /v1/ip/geo/{IP}.json should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo/8.8.8.8.json
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 17: /v1/ip/geo.json?ip=X should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.json?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 18: /v1/ip/geo.js (no IP param) should NOT be cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.js
--- more_headers
X-IP: 8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: private


=== TEST 19: /v1/ip/geo/{IP}.js should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo/8.8.8.8.js
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000


=== TEST 20: /v1/ip/geo.js?ip=X should BE cacheable
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/ip.conf";
--- request
GET /v1/ip/geo.js?ip=8.8.8.8
--- no_error_log
[error]
--- response_headers
Cache-Control: private, no-store
Cloudflare-CDN-Cache-Control: max-age=31536000

