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
=== TEST 1: Valid config
--- http_config eval
"$::HttpConfig"
--- config
    include "../../../conf/v1/hooks.conf";
    location /sanity {
        echo "OK";
    }
--- request
GET /sanity
--- no_error_log
[error]
--- response_body
OK
