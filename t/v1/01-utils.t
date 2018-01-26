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
    lua_package_path "$pwd/lib/?.lua;$pwd/repos/lua-resty-dns/lib/?.lua;$pwd/repos/lua-resty-http/lib/?.lua;;";
    real_ip_header X-IP;
    set_real_ip_from  127.0.0.1/32;
};

our $UpstreamConfig = qq{
    server {
        listen 8080;
        location /t {
            echo 'OK';
        }
    }
};

run_tests();

__DATA__
=== TEST 1: Test split
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local split       = require("geojs.utils").split
            local cjson       = require("cjson")
            local json_encode = cjson.encode
            local test_string = 'first,second'
            ngx.say(json_encode(split(test_string, ',')))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
["first","second"]


=== TEST 2: Test whitespace before text
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local trim        = require("geojs.utils").trim
            local test_string = '  test string'
            ngx.say(trim(test_string))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
test string


=== TEST 3: Test whitespace after text
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local trim        = require("geojs.utils").trim
            local test_string = 'test string   '
            ngx.say(trim(test_string))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
test string


=== TEST 4: Get PTR record
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        set $geojs_dns_server '8.8.8.8';
        content_by_lua_block {
            local getptr = require("geojs.utils").get_ptr
            local ptr    = getptr('8.8.8.8')
            ngx.say(ptr)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
google-public-dns-a.google.com


=== TEST 5: Test upstream req
--- http_config eval
"$::HttpConfig
$::UpstreamConfig"
--- config
    location /t {
        content_by_lua_block {
            local upstreamreq = require("geojs.utils").upstream_req
            local req         = upstreamreq('/t', '8.8.8.8')
            ngx.print(req)
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK
