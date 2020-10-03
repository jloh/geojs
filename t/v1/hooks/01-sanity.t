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
    set_real_ip_from  127.0.0.1/32;
};

no_long_string();
no_diff();
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
