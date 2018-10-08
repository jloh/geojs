local ngx_log    = ngx.log
local ngx_var    = ngx.var
local escape_uri = ngx.escape_uri
local ngx_re     = ngx.re
local geo        = require('resty.maxminddb')
local geo_asn    = require('resty.maxminddb_asn')

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

local country_code_3 = {
    ["AD"] = "AND",
    ["AE"] = "ARE",
    ["AF"] = "AFG",
    ["AG"] = "ATG",
    ["AI"] = "AIA",
    ["AL"] = "ALB",
    ["AM"] = "ARM",
    ["AO"] = "AGO",
    ["AQ"] = "ATA",
    ["AR"] = "ARG",
    ["AS"] = "ASM",
    ["AT"] = "AUT",
    ["AU"] = "AUS",
    ["AW"] = "ABW",
    ["AX"] = "ALA",
    ["AZ"] = "AZE",
    ["BA"] = "BIH",
    ["BB"] = "BRB",
    ["BD"] = "BGD",
    ["BE"] = "BEL",
    ["BF"] = "BFA",
    ["BG"] = "BGR",
    ["BH"] = "BHR",
    ["BI"] = "BDI",
    ["BJ"] = "BEN",
    ["BL"] = "BLM",
    ["BM"] = "BMU",
    ["BN"] = "BRN",
    ["BO"] = "BOL",
    ["BQ"] = "BES",
    ["BR"] = "BRA",
    ["BS"] = "BHS",
    ["BT"] = "BTN",
    ["BV"] = "BVT",
    ["BW"] = "BWA",
    ["BY"] = "BLR",
    ["BZ"] = "BLZ",
    ["CA"] = "CAN",
    ["CC"] = "CCK",
    ["CD"] = "COD",
    ["CF"] = "CAF",
    ["CG"] = "COG",
    ["CH"] = "CHE",
    ["CI"] = "CIV",
    ["CK"] = "COK",
    ["CL"] = "CHL",
    ["CM"] = "CMR",
    ["CN"] = "CHN",
    ["CO"] = "COL",
    ["CR"] = "CRI",
    ["CU"] = "CUB",
    ["CV"] = "CPV",
    ["CW"] = "CUW",
    ["CX"] = "CXR",
    ["CY"] = "CYP",
    ["CZ"] = "CZE",
    ["DE"] = "DEU",
    ["DJ"] = "DJI",
    ["DK"] = "DNK",
    ["DM"] = "DMA",
    ["DO"] = "DOM",
    ["DZ"] = "DZA",
    ["EC"] = "ECU",
    ["EE"] = "EST",
    ["EG"] = "EGY",
    ["EH"] = "ESH",
    ["ER"] = "ERI",
    ["ES"] = "ESP",
    ["ET"] = "ETH",
    ["FI"] = "FIN",
    ["FJ"] = "FJI",
    ["FK"] = "FLK",
    ["FM"] = "FSM",
    ["FO"] = "FRO",
    ["FR"] = "FRA",
    ["GA"] = "GAB",
    ["GB"] = "GBR",
    ["GD"] = "GRD",
    ["GE"] = "GEO",
    ["GF"] = "GUF",
    ["GG"] = "GGY",
    ["GH"] = "GHA",
    ["GI"] = "GIB",
    ["GL"] = "GRL",
    ["GM"] = "GMB",
    ["GN"] = "GIN",
    ["GP"] = "GLP",
    ["GQ"] = "GNQ",
    ["GR"] = "GRC",
    ["GS"] = "SGS",
    ["GT"] = "GTM",
    ["GU"] = "GUM",
    ["GW"] = "GNB",
    ["GY"] = "GUY",
    ["HK"] = "HKG",
    ["HM"] = "HMD",
    ["HN"] = "HND",
    ["HR"] = "HRV",
    ["HT"] = "HTI",
    ["HU"] = "HUN",
    ["ID"] = "IDN",
    ["IE"] = "IRL",
    ["IL"] = "ISR",
    ["IM"] = "IMN",
    ["IN"] = "IND",
    ["IO"] = "IOT",
    ["IQ"] = "IRQ",
    ["IR"] = "IRN",
    ["IS"] = "ISL",
    ["IT"] = "ITA",
    ["JE"] = "JEY",
    ["JM"] = "JAM",
    ["JO"] = "JOR",
    ["JP"] = "JPN",
    ["KE"] = "KEN",
    ["KG"] = "KGZ",
    ["KH"] = "KHM",
    ["KI"] = "KIR",
    ["KM"] = "COM",
    ["KN"] = "KNA",
    ["KP"] = "PRK",
    ["KR"] = "KOR",
    ["XK"] = "XKX",
    ["KW"] = "KWT",
    ["KY"] = "CYM",
    ["KZ"] = "KAZ",
    ["LA"] = "LAO",
    ["LB"] = "LBN",
    ["LC"] = "LCA",
    ["LI"] = "LIE",
    ["LK"] = "LKA",
    ["LR"] = "LBR",
    ["LS"] = "LSO",
    ["LT"] = "LTU",
    ["LU"] = "LUX",
    ["LV"] = "LVA",
    ["LY"] = "LBY",
    ["MA"] = "MAR",
    ["MC"] = "MCO",
    ["MD"] = "MDA",
    ["ME"] = "MNE",
    ["MF"] = "MAF",
    ["MG"] = "MDG",
    ["MH"] = "MHL",
    ["MK"] = "MKD",
    ["ML"] = "MLI",
    ["MM"] = "MMR",
    ["MN"] = "MNG",
    ["MO"] = "MAC",
    ["MP"] = "MNP",
    ["MQ"] = "MTQ",
    ["MR"] = "MRT",
    ["MS"] = "MSR",
    ["MT"] = "MLT",
    ["MU"] = "MUS",
    ["MV"] = "MDV",
    ["MW"] = "MWI",
    ["MX"] = "MEX",
    ["MY"] = "MYS",
    ["MZ"] = "MOZ",
    ["NA"] = "NAM",
    ["NC"] = "NCL",
    ["NE"] = "NER",
    ["NF"] = "NFK",
    ["NG"] = "NGA",
    ["NI"] = "NIC",
    ["NL"] = "NLD",
    ["NO"] = "NOR",
    ["NP"] = "NPL",
    ["NR"] = "NRU",
    ["NU"] = "NIU",
    ["NZ"] = "NZL",
    ["OM"] = "OMN",
    ["PA"] = "PAN",
    ["PE"] = "PER",
    ["PF"] = "PYF",
    ["PG"] = "PNG",
    ["PH"] = "PHL",
    ["PK"] = "PAK",
    ["PL"] = "POL",
    ["PM"] = "SPM",
    ["PN"] = "PCN",
    ["PR"] = "PRI",
    ["PS"] = "PSE",
    ["PT"] = "PRT",
    ["PW"] = "PLW",
    ["PY"] = "PRY",
    ["QA"] = "QAT",
    ["RE"] = "REU",
    ["RO"] = "ROU",
    ["RS"] = "SRB",
    ["RU"] = "RUS",
    ["RW"] = "RWA",
    ["SA"] = "SAU",
    ["SB"] = "SLB",
    ["SC"] = "SYC",
    ["SD"] = "SDN",
    ["SS"] = "SSD",
    ["SE"] = "SWE",
    ["SG"] = "SGP",
    ["SH"] = "SHN",
    ["SI"] = "SVN",
    ["SJ"] = "SJM",
    ["SK"] = "SVK",
    ["SL"] = "SLE",
    ["SM"] = "SMR",
    ["SN"] = "SEN",
    ["SO"] = "SOM",
    ["SR"] = "SUR",
    ["ST"] = "STP",
    ["SV"] = "SLV",
    ["SX"] = "SXM",
    ["SY"] = "SYR",
    ["SZ"] = "SWZ",
    ["TC"] = "TCA",
    ["TD"] = "TCD",
    ["TF"] = "ATF",
    ["TG"] = "TGO",
    ["TH"] = "THA",
    ["TJ"] = "TJK",
    ["TK"] = "TKL",
    ["TL"] = "TLS",
    ["TM"] = "TKM",
    ["TN"] = "TUN",
    ["TO"] = "TON",
    ["TR"] = "TUR",
    ["TT"] = "TTO",
    ["TV"] = "TUV",
    ["TW"] = "TWN",
    ["TZ"] = "TZA",
    ["UA"] = "UKR",
    ["UG"] = "UGA",
    ["UM"] = "UMI",
    ["US"] = "USA",
    ["UY"] = "URY",
    ["UZ"] = "UZB",
    ["VA"] = "VAT",
    ["VC"] = "VCT",
    ["VE"] = "VEN",
    ["VG"] = "VGB",
    ["VI"] = "VIR",
    ["VN"] = "VNM",
    ["VU"] = "VUT",
    ["WF"] = "WLF",
    ["WS"] = "WSM",
    ["YE"] = "YEM",
    ["YT"] = "MYT",
    ["ZA"] = "ZAF",
    ["ZM"] = "ZMB",
    ["ZW"] = "ZWE",
    ["CS"] = "SCG",
    ["AN"] = "ANT"
}

local _M = {
    _VERSION = "0.0.2"
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
    if req_args.callback then
        callback = escape_uri(req_args.callback)
    else
        callback = default
    end
    return callback
end

-- Maxmind DB implemntation

function init_dbs()
    -- Init our DBs if they haven't been
    if not geo.initted() then
      geo.init("/usr/share/GeoIP/GeoLite2-City.mmdb")
    end

    if not geo_asn.initted() then
        geo_asn.init("/usr/share/GeoIP/GeoLite2-ASN.mmdb")
    end
end

local function geoip_lookup(ip)
    -- Ensure DBs are init'd
    init_dbs()

    -- Lookup Geo data
    local ip_geo, ip_geo_err = geo.lookup(ip)
    local ip_asn, ip_asn_err = geo_asn.lookup(ip)

    local ip_data = {}

    for k,v in pairs(ip_geo) do ip_data[k] = v end
    for k,v in pairs(ip_asn) do ip_data[k] = v end

    -- Add 3 letter country code
    ip_data['country']["iso_code3"] = country_code_3[ip_geo['country']['iso_code']]

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
        ["ip"]             = ip,
        ["country"]        = lookup["country"]["names"]["en"],
        ["country_code"]   = lookup["country"]["iso_code"],
        ["country_code3"]  = lookup["country"]["iso_code3"],
        ["continent_code"] = lookup["continent"]["code"],
        ["city"]           = lookup["city"]["names"]["en"],
        ["region"]         = lookup["subdivisions"][1]["names"]["en"],
        ["latitude"]       = lookup["location"]["latitude"],
        ["longitude"]      = lookup["location"]["longitude"],
        ["accuracy"]       = lookup["location"]["accuracy_radius"],
        ["timezone"]       = lookup["location"]["time_zone"],
        ["organization"]   = lookup["autonomous_system_number"] .. ' ' .. lookup["autonomous_system_organization"]
    }

    return res
end

return _M
