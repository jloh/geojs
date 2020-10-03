local ngx_log    = ngx.log
local ngx_var    = ngx.var
local escape_uri = ngx.escape_uri
local ngx_re     = ngx.re
local geo        = require('resty.maxminddb')
local geo_asn    = require('resty.maxminddb_asn')
local codes      = require('geojs.codes')

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
    _VERSION = "0.0.2"
}

local default_geo_lookup = {
    ["city"] = {
        ["names"] = {}
    },
    ["continent"] = {
        ["names"] = {}
    },
    ["country"] = {
        ["names"] = {}
    },
    ["location"] = {},
    ["postal"] = {},
    ["registered_country"] = {
        ["names"] = {}
    },
    ["subdivisions"] = {{
        ["names"] = {}
    }}
}

local default_asn_lookup = {
    ["autonomous_system_number"] = 64512, -- Start of the private ASN block
    ["autonomous_system_organization"] = "Unknown"
}

local config = {
    http = {
        timeout  = 500,
        upstream = "http://127.0.0.1:8080",
    },
}

-- THe below two functions are taken from the ledge codebase under the 2-clause BSD license.
-- This code was written by James Hurst james@pintsized.co.uk (https://github.com/pintsized/ledge)
--
-- Returns a new table, recursively copied from the one given, retaining
-- metatable assignment.
--
-- @param   table   table to be copied
-- @return  table
local function tbl_copy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == "table" then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[tbl_copy(orig_key)] = tbl_copy(orig_value)
        end
        setmetatable(copy, tbl_copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end


-- Returns a new table, recursively copied from the combination of the given
-- table `t1`, with any missing fields copied from `defaults`.
--
-- If `defaults` is of type "fixed field" and `t1` contains a field name not
-- present in the defults, an error will be thrown.
--
-- @param   table   t1
-- @param   table   defaults
-- @return  table   a new table, recursively copied and merged
local function tbl_copy_merge_defaults(t1, defaults)
    if t1 == nil then t1 = {} end
    if defaults == nil then defaults = {} end
    if type(t1) == "table" and type(defaults) == "table" then
        local copy = {}
        for t1_key, t1_value in next, t1, nil do
            copy[tbl_copy(t1_key)] = tbl_copy_merge_defaults(
                t1_value, tbl_copy(defaults[t1_key])
            )
        end
        for defaults_key, defaults_value in next, defaults, nil do
            if t1[defaults_key] == nil then
                copy[tbl_copy(defaults_key)] = tbl_copy(defaults_value)
            end
        end
        return copy
    else
        return t1 -- not a table
    end
end
_M.tbl_copy_merge_defaults = tbl_copy_merge_defaults


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
    local ptr
    for _, ans in ipairs(answers) do
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

    local i, err = iconv:new(to, from)
    if not i then
        ngx_log(log_level.ERR, "failed to initiate iconv: ", err)
        return string
    end
    return i:convert(string)
end

function _M.validate_ip(ip)
    -- Should match 8.8.8.8
    local regex = [[^((([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))|(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]))$]]
    local m, err = ngx_re.match(ip, regex)
    if m then
        return true
    else
        return false
    end
end

-- Generates callbacks
-- Most important part is it escapes them from possibly dodgy content
function _M.generate_callback(default, req_args)
    local callback
    if req_args.callback then
        callback = escape_uri(req_args.callback)
    else
        callback = default
    end
    return callback
end

-- Maxmind DB implemntation
local function geoip_lookup(ip)
    -- Init our DBs if they haven't been
    if not geo.initted() then
        geo.init("/usr/share/GeoIP/GeoLite2-City.mmdb")
    end

    if not geo_asn.initted() then
        geo_asn.init("/usr/share/GeoIP/GeoLite2-ASN.mmdb")
    end

    -- Lookup Geo data
    local ip_geo, _ = geo.lookup(ip)
    local ip_asn, _ = geo_asn.lookup(ip)

    -- Copy in our default/fallback values
    ip_geo = tbl_copy_merge_defaults(ip_geo, default_geo_lookup)
    ip_asn = tbl_copy_merge_defaults(ip_asn, default_asn_lookup)

    local ip_data = {}

    -- Merge our two tables
    for k,v in pairs(ip_geo) do ip_data[k] = v end
    for k,v in pairs(ip_asn) do ip_data[k] = v end

    -- Add 3 letter country code
    if ip_data['country']['iso_code'] then ip_data['country']["iso_code3"] = codes.country_code_3[ip_geo['country']['iso_code']] end

    -- Copy in our defaults so if info is missing we fail gracefully
    return ip_data
end
_M.geoip_lookup = geoip_lookup

function _M.country_lookup(ip)
    -- Lookup IP
    local lookup = geoip_lookup(ip)
    local res = {
        ["country"]   = lookup["country"]["iso_code"],
        ["country_3"] = lookup["country"]["iso_code3"],
        ["ip"]        = ip,
        ["name"]      = lookup["country"]["names"]["en"]
    }
    return res
end

function _M.geo_lookup(ip)
    -- Lookup IP
    local lookup = geoip_lookup(ip)
    local res = {
        ["ip"]                = ip,
        ["area_code"]         = '0', -- depreciated but we should return a value
        ["country"]           = lookup["country"]["names"]["en"],
        ["country_code"]      = lookup["country"]["iso_code"],
        ["country_code3"]     = lookup["country"]["iso_code3"],
        ["continent_code"]    = lookup["continent"]["code"],
        ["city"]              = lookup["city"]["names"]["en"],
        ["region"]            = lookup["subdivisions"][1]["names"]["en"],
        ["latitude"]          = tostring(lookup["location"]["latitude"]), -- Sadly these two were an int at the start so can't be until v2
        ["longitude"]         = tostring(lookup["location"]["longitude"]),
        ["accuracy"]          = lookup["location"]["accuracy_radius"],
        ["timezone"]          = lookup["location"]["time_zone"],
        ["organization"]      = 'AS' .. table.concat({lookup["autonomous_system_number"], lookup["autonomous_system_organization"]}, ' '),
        ["asn"]               = lookup["autonomous_system_number"],
        ["organization_name"] = lookup["autonomous_system_organization"]
    }

    return res
end

return _M
