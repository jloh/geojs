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
        set $geojs_dns_server '1.1.1.1';
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


=== TEST 5: Bad DNS server
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        set $geojs_dns_server '127.0.0.1';
        content_by_lua_block {
            local getptr = require("geojs.utils").get_ptr
            local ptr    = getptr('8.8.8.8')
            ngx.say(ptr)
        }
    }
--- request
GET /t
--- response_body
Failed to query DNS servers


=== TEST 6: Bad PTR record
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        set $geojs_dns_server '1.1.1.1';
        content_by_lua_block {
            local getptr = require("geojs.utils").get_ptr
            local ptr    = getptr('192.168.0.1')
            ngx.say(ptr)
        }
    }
--- request
GET /t
--- response_body
Failed to get PTR record


=== TEST 7: Test upstream req
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


=== TEST 8: Failed upstream req
--- http_config eval
"$::HttpConfig"
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
--- response_body chomp
nil


=== TEST 9: Iconv encoding
--- http_config eval
"$::HttpConfig"
--- config
    charset utf8;
    location /t {
        default_type text/plain;
        charset utf-8;
        content_by_lua_block {
            local to_utf8 = require("geojs.utils").to_utf8
            local string  = 'Ã'
            ngx.print(to_utf8(string))
            ngx.log(ngx.ERR, 'hello: ', to_utf8(string))
        }
    }
--- request
GET /t
--- response_body chomp
Ã0


=== TEST 10: Validate IPv4/IPv6 IPs
--- http_config eval
"$::HttpConfig"
--- config
    charset utf8;
    location /t {
        default_type text/plain;
        charset utf-8;
        content_by_lua_block {
            local validate_ip = require("geojs.utils").validate_ip
            local args = ngx.req.get_uri_args()
            local ip  = args.ip
            if validate_ip(ip) then
                ngx.print("OK")
            end
        }
    }
--- request eval
["GET /t?ip=8.8.8.8",
"GET /t?ip=2001:4860:4860::8888"]
--- no_error_log
[error]
--- response_body eval
["OK","OK"]


=== TEST 11: Fail on bad IPs
--- http_config eval
"$::HttpConfig"
--- config
    charset utf8;
    location /t {
        default_type text/plain;
        charset utf-8;
        content_by_lua_block {
            local validate_ip = require("geojs.utils").validate_ip
            local args = ngx.req.get_uri_args()
            local ip  = args.ip
            if not validate_ip(ip) then
                ngx.print("OK")
            end
        }
    }
--- request eval
["GET /t?ip=8.8.8.256",
"GET /t?ip=2001:4860:4860::88888"]
--- no_error_log
[error]
--- response_body eval
["OK","OK"]


=== TEST 12: Test geo_lookup
--- http_config eval
"$::HttpConfig"
--- config
    charset utf8;
    location /t {
        default_type text/plain;
        charset utf-8;
        content_by_lua_block {
            local geo_lookup = require("geojs.utils").geoip_lookup
            local args       = ngx.req.get_uri_args()
            local ip         = args.ip
            local cjson      = require("cjson")

            ngx.print(cjson.encode(geo_lookup(ip)))
        }
    }
--- request eval
["GET /t?ip=8.8.8.9",
"GET /t?ip=2001:4860:4860::8888"]
--- no_error_log
[error]
--- response_body eval
['{"subdivisions":[{"names":{}}],"autonomous_system_number":15169,"registered_country":{"geoname_id":6252001,"names":{"en":"United States","ru":"США","fr":"États-Unis","pt-BR":"Estados Unidos","zh-CN":"美国","es":"Estados Unidos","de":"USA","ja":"アメリカ合衆国"},"iso_code":"US"},"continent":{"geoname_id":6255149,"names":{"en":"North America","ru":"Северная Америка","fr":"Amérique du Nord","pt-BR":"América do Norte","zh-CN":"北美洲","es":"Norteamérica","de":"Nordamerika","ja":"北アメリカ"},"code":"NA"},"postal":{},"city":{"names":{}},"country":{"geoname_id":6252001,"iso_code3":"USA","names":{"en":"United States","ru":"США","fr":"États-Unis","pt-BR":"Estados Unidos","zh-CN":"美国","es":"Estados Unidos","de":"USA","ja":"アメリカ合衆国"},"iso_code":"US"},"location":{"latitude":37.751,"accuracy_radius":1000,"longitude":-97.822},"autonomous_system_organization":"Google LLC"}','{"subdivisions":[{"names":{}}],"autonomous_system_number":15169,"registered_country":{"geoname_id":6252001,"names":{"en":"United States","ru":"США","fr":"États-Unis","pt-BR":"Estados Unidos","zh-CN":"美国","es":"Estados Unidos","de":"USA","ja":"アメリカ合衆国"},"iso_code":"US"},"continent":{"geoname_id":6255149,"names":{"en":"North America","ru":"Северная Америка","fr":"Amérique du Nord","pt-BR":"América do Norte","zh-CN":"北美洲","es":"Norteamérica","de":"Nordamerika","ja":"北アメリカ"},"code":"NA"},"postal":{},"city":{"names":{}},"country":{"geoname_id":6252001,"iso_code3":"USA","names":{"en":"United States","ru":"США","fr":"États-Unis","pt-BR":"Estados Unidos","zh-CN":"美国","es":"Estados Unidos","de":"USA","ja":"アメリカ合衆国"},"iso_code":"US"},"location":{"latitude":37.751,"accuracy_radius":100,"longitude":-97.822},"autonomous_system_organization":"Google LLC"}']
