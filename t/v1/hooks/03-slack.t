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
    lua_package_path "$pwd/lib/?.lua;$pwd/repos/lua-resty-dns/lib/?.lua;$pwd/repos/lua-resty-http/lib/?.lua;$pwd/repos/lua-resty-iconv/lualib/?.lua;$pwd/repos/lua-resty-reqargs/lib/?.lua;$pwd/repos/lua-resty-upload/lib/?.lua;;";
    real_ip_header X-Real-IP;
    set_real_ip_from  127.0.0.1/32;
};

our $UpstreamConfig = qq{
    server {
        listen 8080;
        include $pwd/conf/v1/ip.conf;
    }
};

run_tests();

__DATA__
=== TEST 1: Webhook
--- http_config eval
"$::HttpConfig
$::UpstreamConfig"
--- config
    include "../../../conf/v1/hooks.conf";
    set $geojs_slack_token '1234';
    set $geojs_dns_server '8.8.8.8';
--- more_headers
Content-type: application/x-www-form-urlencoded
--- request eval
"POST /v1/hooks/slack
".CORE::join('&',
'token=1234',
'text=8.8.8.8 display',
'command=geojs')
--- no_error_log
[error]

=== TEST 2: Bad token
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/hooks.conf";
    set $geojs_slack_token '1234';
    set $geojs_dns_server '8.8.8.8';
--- more_headers
Content-type: application/x-www-form-urlencoded
--- request eval
"POST /v1/hooks/slack
".CORE::join("&",
"token=12",
"text=8.8.8.8 display",
"command=geojs")
--- error_code: 403

=== TEST 3: Bad IP
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/hooks.conf";
    set $geojs_slack_token '1234';
    set $geojs_dns_server '8.8.8.8';
--- more_headers
Content-type: application/x-www-form-urlencoded
--- request eval
"POST /v1/hooks/slack
".CORE::join("&",
"token=1234",
"text=google.com",
"command=geojs")
--- no_error_log
[error]
--- response_body
{"attachments":[{"text":"Hmmm. Looks like you've given us a bad IP (`google.com`). This command only accepts IPs (IPv6 or IPv4) for now, sorry!","mrkdwn_in":["text"],"fallback":"Hmmm. Looks like you've given us a bad IP. This command only accepts IPs (IPv6 or IPv4) for now, sorry!","color":"danger"}]}
