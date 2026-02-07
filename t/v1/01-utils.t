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

no_long_string();
no_diff();
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
dns.google


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


=== TEST 12: Test geoip_lookup
--- http_config eval
"$::HttpConfig"
--- config
    charset utf8;
    location /t {
        default_type text/plain;
        charset utf-8;
        content_by_lua_block {
            local geoip_lookup  = require("geojs.utils").geoip_lookup
            local sorted_encode = require("geojs.utils").sorted_encode
            local args          = ngx.req.get_uri_args()
            local ip            = args.ip

            ngx.print(sorted_encode(geoip_lookup(ip)))
        }
    }
--- request eval
["GET /t?ip=8.8.8.9",
"GET /t?ip=2001:4860:4860::8888"]
--- no_error_log
[error]
--- response_body eval
['{"autonomous_system_number":15169,"autonomous_system_organization":"Google LLC","city":{"names":{}},"continent":{"code":"NA","geoname_id":6255149,"names":{"de":"Nordamerika","en":"North America","es":"Norteamérica","fr":"Amérique du Nord","ja":"北アメリカ","pt-BR":"América do Norte","ru":"Северная Америка","zh-CN":"北美洲"}},"country":{"geoname_id":6252001,"iso_code":"US","iso_code3":"USA","names":{"de":"USA","en":"United States","es":"Estados Unidos","fr":"États Unis","ja":"アメリカ","pt-BR":"EUA","ru":"США","zh-CN":"美国"}},"location":{"accuracy_radius":1000,"latitude":37.751,"longitude":-97.822,"time_zone":"America\/Chicago"},"postal":{},"registered_country":{"geoname_id":6252001,"iso_code":"US","names":{"de":"USA","en":"United States","es":"Estados Unidos","fr":"États Unis","ja":"アメリカ","pt-BR":"EUA","ru":"США","zh-CN":"美国"}},"subdivisions":[{"names":{}}]}','{"autonomous_system_number":15169,"autonomous_system_organization":"Google LLC","city":{"names":{}},"continent":{"code":"NA","geoname_id":6255149,"names":{"de":"Nordamerika","en":"North America","es":"Norteamérica","fr":"Amérique du Nord","ja":"北アメリカ","pt-BR":"América do Norte","ru":"Северная Америка","zh-CN":"北美洲"}},"country":{"geoname_id":6252001,"iso_code":"US","iso_code3":"USA","names":{"de":"USA","en":"United States","es":"Estados Unidos","fr":"États Unis","ja":"アメリカ","pt-BR":"EUA","ru":"США","zh-CN":"美国"}},"location":{"accuracy_radius":1000,"latitude":37.751,"longitude":-97.822,"time_zone":"America\/Chicago"},"postal":{},"registered_country":{"geoname_id":6252001,"iso_code":"US","names":{"de":"USA","en":"United States","es":"Estados Unidos","fr":"États Unis","ja":"アメリカ","pt-BR":"EUA","ru":"США","zh-CN":"美国"}},"subdivisions":[{"names":{}}]}']


=== TEST 13: Test geo_lookup
--- http_config eval
"$::HttpConfig"
--- config
    charset utf8;
    location /t {
        default_type text/plain;
        charset utf-8;
        content_by_lua_block {
            local geo_lookup    = require("geojs.utils").geo_lookup
            local sorted_encode = require("geojs.utils").sorted_encode
            local args          = ngx.req.get_uri_args()
            local ip            = args.ip

            ngx.print(sorted_encode(geo_lookup(ip)))
        }
    }
--- request eval
["GET /t?ip=8.8.8.8",
"GET /t?ip=2001:4860:4860::8888"]
--- no_error_log
[error]
--- response_body eval
['{"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"8.8.8.8","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"}','{"accuracy":1000,"area_code":"0","asn":15169,"continent_code":"NA","country":"United States","country_code":"US","country_code3":"USA","ip":"2001:4860:4860::8888","latitude":"37.751","longitude":"-97.822","organization":"AS15169 Google LLC","organization_name":"Google LLC","timezone":"America\/Chicago"}']


=== TEST 14: Test country_lookup
--- http_config eval
"$::HttpConfig"
--- config
    charset utf8;
    location /t {
        default_type text/plain;
        charset utf-8;
        content_by_lua_block {
            local country_lookup = require("geojs.utils").country_lookup
            local sorted_encode  = require("geojs.utils").sorted_encode
            local args           = ngx.req.get_uri_args()
            local ip             = args.ip

            ngx.print(sorted_encode(country_lookup(ip)))
        }
    }
--- request eval
["GET /t?ip=8.8.8.8",
"GET /t?ip=2001:4860:4860::8888"]
--- no_error_log
[error]
--- response_body eval
['{"country":"US","country_3":"USA","ip":"8.8.8.8","name":"United States"}', '{"country":"US","country_3":"USA","ip":"2001:4860:4860::8888","name":"United States"}']


=== TEST 15: Test sorted_encode produces sorted keys
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local sorted_encode = require("geojs.utils").sorted_encode
            -- Keys intentionally out of order
            local data = {
                zebra = "last",
                apple = "first",
                mango = "middle"
            }
            ngx.say(sorted_encode(data))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
{"apple":"first","mango":"middle","zebra":"last"}


=== TEST 16: Test sorted_encode with nested tables
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local sorted_encode = require("geojs.utils").sorted_encode
            local data = {
                outer_z = "z",
                outer_a = "a",
                nested = {
                    inner_z = "z",
                    inner_a = "a"
                }
            }
            ngx.say(sorted_encode(data))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
{"nested":{"inner_a":"a","inner_z":"z"},"outer_a":"a","outer_z":"z"}


=== TEST 17: Test sorted_encode with arrays
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local sorted_encode = require("geojs.utils").sorted_encode
            local data = {
                items = {"first", "second", "third"},
                name = "test"
            }
            ngx.say(sorted_encode(data))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
{"items":["first","second","third"],"name":"test"}


=== TEST 18: Test sorted_encode with empty tables
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local sorted_encode = require("geojs.utils").sorted_encode
            local data = {
                empty = {},
                nested = {
                    also_empty = {}
                }
            }
            ngx.say(sorted_encode(data))
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
{"empty":{},"nested":{"also_empty":{}}}


=== TEST 19: Test is_private_ip with RFC1918 addresses
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local is_private_ip = require("geojs.utils").is_private_ip
            -- Test RFC1918 private ranges
            local private_ips = {
                "10.0.0.1",
                "10.255.255.255",
                "172.16.0.1",
                "172.31.255.255",
                "192.168.0.1",
                "192.168.255.255",
            }
            for _, ip in ipairs(private_ips) do
                if not is_private_ip(ip) then
                    ngx.say("FAIL: " .. ip .. " should be private")
                    return
                end
            end
            ngx.say("OK")
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 20: Test is_private_ip with loopback addresses
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local is_private_ip = require("geojs.utils").is_private_ip
            -- Test loopback addresses
            local loopback_ips = {
                "127.0.0.1",
                "127.0.0.2",
                "127.255.255.255",
            }
            for _, ip in ipairs(loopback_ips) do
                if not is_private_ip(ip) then
                    ngx.say("FAIL: " .. ip .. " should be private")
                    return
                end
            end
            ngx.say("OK")
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 21: Test is_private_ip with link-local addresses
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local is_private_ip = require("geojs.utils").is_private_ip
            -- Test link-local addresses (169.254.x.x)
            local link_local_ips = {
                "169.254.0.1",
                "169.254.255.255",
            }
            for _, ip in ipairs(link_local_ips) do
                if not is_private_ip(ip) then
                    ngx.say("FAIL: " .. ip .. " should be private")
                    return
                end
            end
            ngx.say("OK")
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 22: Test is_private_ip with public addresses
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local is_private_ip = require("geojs.utils").is_private_ip
            -- Test public addresses (should return false)
            local public_ips = {
                "8.8.8.8",
                "1.1.1.1",
                "208.67.222.222",
                "142.250.185.46",
            }
            for _, ip in ipairs(public_ips) do
                if is_private_ip(ip) then
                    ngx.say("FAIL: " .. ip .. " should NOT be private")
                    return
                end
            end
            ngx.say("OK")
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 23: Test is_private_ip with IPv6 private addresses
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local is_private_ip = require("geojs.utils").is_private_ip
            -- Test IPv6 private/reserved addresses
            local private_ipv6 = {
                "::1",                          -- loopback
                "fc00::1",                      -- unique local
                "fd00::1",                      -- unique local
                "fe80::1",                      -- link-local
            }
            for _, ip in ipairs(private_ipv6) do
                if not is_private_ip(ip) then
                    ngx.say("FAIL: " .. ip .. " should be private")
                    return
                end
            end
            ngx.say("OK")
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 24: Test is_private_ip with public IPv6 addresses
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local is_private_ip = require("geojs.utils").is_private_ip
            -- Test public IPv6 addresses (should return false)
            local public_ipv6 = {
                "2001:4860:4860::8888",         -- Google DNS
                "2606:4700:4700::1111",         -- Cloudflare DNS
            }
            for _, ip in ipairs(public_ipv6) do
                if is_private_ip(ip) then
                    ngx.say("FAIL: " .. ip .. " should NOT be private")
                    return
                end
            end
            ngx.say("OK")
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 25: Test geoip_lookup with private IP does not log error
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local geoip_lookup  = require("geojs.utils").geoip_lookup
            local sorted_encode = require("geojs.utils").sorted_encode
            -- Lookup a private IP - should not log errors
            local result = geoip_lookup("10.10.123.190")
            -- Check that we got default values back
            if result.autonomous_system_number == 64512 then
                ngx.say("OK")
            else
                ngx.say("FAIL: Expected default ASN 64512, got " .. tostring(result.autonomous_system_number))
            end
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 26: Test geo_lookup with private IP returns sensible defaults
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local geo_lookup    = require("geojs.utils").geo_lookup
            local sorted_encode = require("geojs.utils").sorted_encode
            -- Lookup a private IP
            local result = geo_lookup("127.0.0.1")
            -- Should return the IP and default ASN
            if result.ip == "127.0.0.1" and result.asn == 64512 then
                ngx.say("OK")
            else
                ngx.say("FAIL: ip=" .. tostring(result.ip) .. " asn=" .. tostring(result.asn))
            end
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK


=== TEST 27: Test country_lookup with private IP returns sensible defaults
--- http_config eval
"$::HttpConfig"
--- config
    location /t {
        content_by_lua_block {
            local country_lookup = require("geojs.utils").country_lookup
            -- Lookup a private IP
            local result = country_lookup("192.168.1.1")
            -- Should return the IP with nil country (no data)
            if result.ip == "192.168.1.1" then
                ngx.say("OK")
            else
                ngx.say("FAIL: ip=" .. tostring(result.ip))
            end
        }
    }
--- request
GET /t
--- no_error_log
[error]
--- response_body
OK
