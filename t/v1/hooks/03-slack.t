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
    real_ip_header X-Real-IP;
    set_real_ip_from  127.0.0.1/32;
};

our $UpstreamConfig = qq{
    server {
        listen 8080;
        include $pwd/conf/v1/ip.conf;
    }
};

no_long_string();
no_diff();
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
{"attachments":[{"color":"danger","fallback":"Hmmm. Looks like you've given us a bad IP. This command only accepts IPs (IPv6 or IPv4) for now, sorry!","mrkdwn_in":["text"],"text":"Hmmm. Looks like you've given us a bad IP (`google.com`). This command only accepts IPs (IPv6 or IPv4) for now, sorry!"}]}

=== TEST 4: Help command
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
"text=help",
"command=geojs")
--- no_error_log
[error]
--- response_body
{"text":"Having some trouble? The GeoJS slack app can be used like so `\/geojs 8.8.8.8`. Give it a try!\nIf you continue to have trouble reach out to us at contact@geojs.io"}
