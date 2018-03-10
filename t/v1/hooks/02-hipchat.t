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
        set \$geojs_dns_server '8.8.8.8';
    }
};

our $JSONPayload = qq{
    {
      "event": "room_message",
      "item": {
        "message": {
          "date": "2018-03-01T00:49:10.541852+00:00",
          "from": {
            "id": 159,
            "links": {
              "self": "https:\/\/hipchat.example.com\/v2\/user\/123"
            },
            "mention_name": "test",
            "name": "John Doe",
            "version": "123456"
          },
          "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
          "mentions": [
          ],
          "message": "/geojs 8.8.8.8",
          "type": "message"
        },
        "room": {
          "id": 10,
          "is_archived": false,
          "links": {
            "members": "https:\/\/hipchat.example.com\/v2\/room\/10\/member",
            "participants": "https:\/\/hipchat.example.com\/v2\/room\/10\/participant",
            "self": "https:\/\/hipchat.example.com\/v2\/room\/10",
            "webhooks": "https:\/\/hipchat.example.com\/v2\/room\/10\/webhook"
          },
          "name": "Webhook Lounge",
          "privacy": "private",
          "version": "CB296BBB"
        }
      },
      "oauth_client_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
      "webhook_id": 2
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
    set $geojs_dns_server '8.8.8.8';
--- more_headers
Content-type: application/json
--- request eval
"POST /v1/hooks/hipchat
$::JSONPayload"
--- no_error_log
[error]
--- no_error_log
[error]
--- response_body
{"notify":"False","message_format":"html","message":"Results for <b>8.8.8.8<\/b><br><br>PTR: google-public-dns-a.google.com<br>Country: United States<br>Organization: AS15169 Google LLC<br><br>Powered by <a href=\"https:\/\/geojs.io\" title=\"GeoJS\">GeoJS<\/a>","card":{"icon":{"url":"https:\/\/static.jloh.co\/geojs\/flags\/v1\/us.png","url@2x":"https:\/\/static.jloh.co\/geojs\/flags\/v1\/2x\/us.png"},"format":"medium","title":"GeoIP results for 8.8.8.8","id":"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx","attributes":[{"label":"Powered by","value":{"label":"GeoJS","url":"https:\/\/geojs.io"}}],"activity":{"html":"<strong>8.8.8.8<\/strong> is a United States IP belonging to AS15169 Google LLC"},"style":"application","description":{"value":"<strong>PTR:<\/strong> google-public-dns-a.google.com","format":"html"}}}
