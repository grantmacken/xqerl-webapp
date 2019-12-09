local _M = {}
local http = require("resty.http").new()

_M.version = '0.0.1'

local exit = ngx.exit

local function requestError( status, msg, description )
  ngx.status = status
  ngx.header.content_type = 'application/json'
  local json = cjson.encode({
      error  = msg,
      error_description = description
    })
  ngx.print(json)
  exit(status)
end


--- Domain DNS Resolution
-- @usage  Given DOMAIN Resolve IP address
-- @return address
-- @return message
-- @parm   sContainerName The name of the docker container
local function getDomainAddress( sDomain )
  local resolver = require("resty.dns.resolver")
  local msg
  local r, err, answers
  r, err = resolver:new{nameservers = {'8.8.8.8'}}
  if not r then
    msg = '- failed to instantiate resolver:' .. err
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
  end
  -- ngx.log(ngx.INFO, ' - instantiated DNS resolver:')
  answers , err = r:tcp_query(sDomain, { qtype = r.TYPE_A })
  if not answers then
    msg = ' - FAILED to get answer from DNS query:' .. err
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
  end
  -- ngx.log(ngx.INFO, ' - query answered by DNS server')
  if answers.errcode then
    msg =  " - FAILED DNS server returned error code: " ..
    answers.errcode ..
    ": " ..
    answers.errstr
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
  end
  -- for i, ans in ipairs(answers) do
  --   ngx.log(ngx.INFO , 'NAME: ' .. ans.name )
  --   ngx.log(ngx.INFO , 'ADDRESS: ' .. ans.address )
  -- end
  if answers[1] == nil then
    msg = 'domain ip NOT address resolved'
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
   else
    msg = 'domain ip address resolved: ' .. answers[1].address
    return answers[1].address , msg
  end
end

--- Container DNS Resolution
-- @usage  Given container name Resolve IP address of container
-- @return address
-- @return message
-- @parm   sContainerName The name of the docker container
local function getAddress( sContainerName )
  local resolver = require("resty.dns.resolver")
  --- docker DNS resolver: 127.0.0.11
  local msg
  local r, err, answers
  r, err = resolver:new{nameservers = {'127.0.0.11'}}
  if not r then
    msg = '- failed to instantiate resolver:' .. err
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
  end
  -- ngx.log(ngx.INFO, ' - instantiated DNS resolver:')
  answers , err = r:tcp_query(sContainerName, { qtype = r.TYPE_A })
  if not answers then
    msg = ' - FAILED to get answer from DNS query:' .. err
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
  end
  -- ngx.log(ngx.INFO, ' - query answered by DNS server')
  if answers.errcode then
    msg =  " - FAILED DNS server returned error code: " ..
    answers.errcode ..
    ": " ..
    answers.errstr
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
  end
  -- for i, ans in ipairs(answers) do
  --   ngx.log(ngx.INFO , 'NAME: ' .. ans.name )
  --   ngx.log(ngx.INFO , 'ADDRESS: ' .. ans.address )
  -- end
  if answers[1] == nil then
    msg = 'container ip NOT address resolved'
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',msg )
   else
    msg = 'container ip address resolved: ' .. answers[1].address
    return answers[1].address , msg
  end
end

---  HTTP connection
local function connect( sAddress, iPort )
  local ok, err = http:connect( sAddress, iPort )
  if not ok then
    ngx.log(ngx.ERR, err)
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',err)
  end
  return 'connected to '  .. sAddress ..  ' on port '  .. iPort
end

---  SSL handshake
local function handshake( sHost )
   -- 4 sslhandshake opts
    local reusedSession = nil   -- defaults to nil
    local serverName = sHost    -- for SNI name resolution
    local sslVerify = false     -- boolean if true make sure the directives set
    -- for lua_ssl_trusted_certificate and lua_ssl_verify_depth
    local sendStatusReq = '' -- boolean OCSP status request
    -- SSL HANDSHAKE
    local shake, err = http:ssl_handshake( reusedSession, serverName, sslVerify)
    if not shake then
      ngx.log(ngx.ERR, 'FAILED to complete SSL handshake' .. err)
    return requestError( ngx.HTTP_BAD_REQUEST,'bad request',err)
    end
    return "SSL Handshake Completed: " .. type(shake)
end

local function reqObj( request )
  local sURL =  request['sURL']
  local sHost = http:parse_uri(sURL)[2]
  local iPort = http:parse_uri(sURL)[3]
  local sPath = http:parse_uri(sURL)[4]
  local sContainerName = request['sContainerName']
  local sAddress, sMsg = getAddress( sContainerName )
  local sConnect =       connect( sAddress, iPort )
  local sHandshake =     handshake( sHost )
  local tHeaders = {}
    -- tHeaders['version'] = 1.1
    tHeaders['Authorization'] =  'Bearer ' .. request['sToken']
    tHeaders['Host'] = sHost
    tHeaders['Content-Type'] = request['sContentType']
  local tRequest = {}
    tRequest['method'] = request['sMethod']
    tRequest['path'] = sPath
    tRequest['ssl_verify'] = false
    tRequest['headers'] = tHeaders
  if ( request['sMethod'] == "POST" or request['sMethod'] == "PUT" )  then
    tRequest['body'] = request['sData']
  end
  return tRequest
end

function _M.eX( oReq )
  -- local pretty = require('resty.prettycjson')
  local sContainerName =  os.getenv("EXIST_CONTAINER_NAME")
  local sAddress, sMsg = getAddress( sContainerName )
  local sConnect = connect( sAddress, 8080 )
  -- ngx.say(sConnect)
  local tHeaders = {}
  tHeaders["Content-Type"] = oReq.contentType
  tHeaders["Authorization"] = 'Basic ' .. oReq.auth
  local tRequest = {}
    tRequest['method'] = oReq.method
    tRequest['path'] = oReq.path
    tRequest['ssl_verify'] = false
    tRequest['headers'] = tHeaders
  if ( oReq['method'] == "POST" or oReq['method'] == "PUT" )  then
    if oReq['contentType'] == 'application/json' then
      tRequest['body'] = cjson.encode(oReq.data)
      -- pretty( oReq.data, '\n','  ')
    else
      tRequest['body'] = oReq.data
    end
  end
  http:set_timeout(10000)
  local response, err = http:request( tRequest )
  ngx.say( " - response status: " .. response.status)
  ngx.say( " - response reason: " .. response.reason)
  return response
end

function _M.eXwrap( sAction )
return [[
<query xmlns="http://exist.sourceforge.net/NS/exist"
 start='1'
 max='9999'
 wrap="no">
<text>
<![CDATA[
xquery version "3.1";
try{
let $nl := "&#10;"
return (
]] ..
sAction
..
[[
)} catch * {
   'ERR:' || $err:code || ': '  || $err:description
}
]] ..']]>' .. [[
</text>
</query>
]]
end

function _M.eXwrapper( oWrap )
return [[
<query xmlns="http://exist.sourceforge.net/NS/exist"
 start='1'
 max='9999'
 wrap="no">
<text>
<![CDATA[
xquery version '3.1';
]] ..
oWrap['sDeclare']
..
[[
try{
]] ..
oWrap['sLet']
..
[[
return (
]] ..
oWrap['sReturn']
..
[[
)} catch * {(
  util:log-system-out(   'ERR:' || $err:code || ': '  || $err:description),
  'ERR:' || $err:code || ': '  || $err:description
)}
]] ..']]>' .. [[
</text>
</query>
]]
end

--- a generic boilerplate response
--  log and send json message and terminate request
-- @usage  Given DOMAIN Resolve IP address
-- @return exit
-- @parm   oRes { }
-- ['status'] = http-status-constant
-- https://github.com/openresty/lua-nginx-module#http-status-constants
-- ['log'] = http-status-constant
-- https://github.com/openresty/lua-nginx-module#nginx-log-level-constants
-- ['err'] 
-- ['msg'] 
function _M.res( oRes )
  ngx.status = oRes['status']
  ngx.header.content_type = 'application/json'
  local oOut = {}
  local oLog = {}

  ngx.log( ngx.INFO, ' - STATUS  ' .. oRes['status'] )
  if oRes['status'] >= oRes['status'] then
    oOut['error']  = oRes['err']
    oOut['message'] =  oRes['msg']
    oLog['level'] =  ngx.WARN
    oLog['message'] =  oRes['msg']
  else
    oOut['info'] =  oRes['msg']
    oLog['level'] =  ngx.INFO
    oLog['message'] =  oRes['msg']
  end
  ngx.log( oLog['level'], ' - ' .. oLog['message'] )
  ngx.print( cjson.encode(oOut) )
  return ngx.exit(oRes['status'])
end



_M.http = http
_M.getAddress = getAddress
_M.getDomainAddress = getDomainAddress
_M.connect = connect
_M.handshake = handshake
_M.reqObj = reqObj

return _M
