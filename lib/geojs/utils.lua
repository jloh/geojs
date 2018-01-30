local ngx_log    = ngx.log
local ngx_var    = ngx.var
local escape_uri = ngx.escape_uri

local log_level = {
    STDERR = ngx.STDERR,
    EMERG  = ngx.EMERG,
    ALERT  = ngx.ALERT,
    CRIT   = ngx.CRIT,
    ERR    = ngx.ERR,
    WARN   = ngx.WARN,
    NOTICE = ngx.NOTICE,
    INFO   = ngx.INFO,
    DEBUG  = ngx.DEBUG
}

local _M = {
    _VERSION = "0.0.1"
}

local config = {
    http = {
        timeout  = 500,
        upstream = "http://127.0.0.1:8080",
    },
}

-- Splits strings!
function _M.split(str, pat)
    local t         = {}  -- NOTE: use {n = 0} in Lua-5.0
    local fpat      = "(.-)" .. pat
    local last_end  = 1
    local s, e, cap = str:find(fpat, 1)
    while s do
        if s ~= 1 or cap ~= "" then
            table.insert(t,cap)
        end
        last_end = e+1
        s, e, cap = str:find(fpat, last_end)
    end
    if last_end <= #str then
        cap = str:sub(last_end)
        table.insert(t, cap)
    end
    return t
end

-- Trim to remove any whitespace we might have
function _M.trim(s)
    return s:match'^()%s*$' and '' or s:match'^%s*(.*%S)'
end

-- Gets a PTR
function _M.get_ptr(ip)
    local resolver = require "resty.dns.resolver"
    local servers  = {ngx.var.geojs_dns_server}
    local r, err = resolver:new{
        nameservers = servers,
        retrans = 2,     -- 2 retransmissions on receive timeout
        timeout = 2000,  -- 2 sec
    }
    if not r then
        ngx_log(log_level.ERR, "failed to instantiate the resolver: ", err)
        return nill
    end
    local answers, err = r:reverse_query(ip)
    if not answers then
        ngx_log(log_level.ERR, "failed to query the DNS server: ", err)
        return 'Failed to query DNS servers'
    end

    if answers.errcode then
        ngx_log(log_level.ERR, "server returned error code: ", answers.errcode,
            ": ", answers.errstr)
        return 'Failed to get PTR record'
    end
    for i, ans in ipairs(answers) do
        ptr = ans.ptrdname
    end
    return ptr
end

-- Makes requests to our upstream server
function _M.upstream_req(reqpath, ip)
	local http  = require "resty.http"
    local httpc = http.new()
    local uri   = config.http.upstream .. reqpath
    local res, err = httpc:request_uri(uri, {
        method  = "GET",
        headers = {
            ["X-Real-IP"] = ip,
	    	["Host"]      = "get.geojs.io",
        }
    })

    if not res then
        ngx_log(log_level.ERR, "failed to request: " .. err)
        return
    end
    return res.body
end

function _M.to_utf8(string)
    local iconv = require "resty.iconv"

    local from  = 'iso-8859-15'
    local to    = 'utf-8'

    local i, err = iconv:new("utf-8","iso-8859-15")
    if not i then
        ngx_log(log_level.ERR, "failed to initiate iconv: ", err)
        return string
    end
    return i:convert(string)
end

-- Generates callbacks
-- Most important part is it escapes them from possibly dodgy content
function _M.generate_callback(default, req_args)
    if req_args.callback then
        callback = escape_uri(req_args.callback)
    else
        callback = default
    end
    return callback
end

return _M
