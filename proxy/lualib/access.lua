local _M = {}
_M.version = '0.0.5'


local cjson = require("cjson")
local httpc = require("resty.http").new()
local jwt = require("resty.jwt")
local reqargs = require("resty.reqargs")
local say = ngx.say
local exit = ngx.exit
local log = ngx.log

--[[
https://indielogin.com/api
If everything is successful, the user will be redirected back to the redirect_uri
you specified in the form. You'll see two parameters in the query string, state
and code. Check that the state matches the value you set originally before continuing.
--]]


local function requestError( status, msg, description )
  ngx.status = status
  ngx.header.content_type = 'application/json'
  local json = cjson.encode({
      error  = msg,
      error_description = description
    })
  ngx.print(json)
  ngx.exit(status)
end


local function verifyCode( code )
 --[[
 At this point you need to verify the code which will also return the website
 of the authenticated user. Make a POST request to https://indielogin.com/auth
 with the code, client_id and redirect_uri, and you will get back the full website
 of the authenticated user.
  --]]
  -- log(ngx.INFO, "Verify the authorization code with IndieLogin.com")
  -- say(code)
  --ngx.log(ngx.INFO, "==========================")
  local scheme, host, port, path = unpack(httpc:parse_uri('https://indielogin.com/auth'))
  httpc:set_timeout(6000) -- one min timeout
  local ok, err = httpc:connect(host, port)
  if not ok then
    local msg = "FAILED to connect to " .. host .. " on port "  .. port .. ' - ERR: ' ..  err
    requestError(ngx.HTTP_UNAUTHORIZED,'unauthorized', msg )
  end
  ----ngx.log(ngx.INFO, ' - connected to '  .. host ..  ' on port '  .. port)
  -- say(' - connected to '  .. host ..  ' on port '  .. port)
  -- say(' - path '  .. path)
 -- say(' - domain '  .. ngx.var.host)

  --
   -- -- 4 sslhandshake opts
   local reusedSession = nil -- defaults to nil
   local serverName = host    -- for SNI name resolution
   local sslVerify = false  -- boolean if true make sure the directives set
   -- for lua_ssl_trusted_certificate and lua_ssl_verify_depth
   local sendStatusReq = '' -- boolean OCSP status request

   local shake, err = httpc:ssl_handshake( reusedSession, serverName, sslVerify)
   if not shake then
     msg = "failed to do SSL handshake: ", err
     return requestError(ngx.HTTP_UNAUTHORIZED,'unauthorized', msg )
   end

  -- say('  - SSL Handshake Completed'  .. type(shake))

    --ngx.log(ngx.INFO, " - SSL Handshake Completed: "  .. type(shake) )
   -- ngx.say(cjson.encode(req))

 local headers = {
      ['Content-Type'] =  'application/x-www-form-urlencoded;charset=UTF-8',
      ['Accept'] = 'application/json'
  }

   local clientID    = 'https://' .. ngx.var.host
   local redirectURI = 'https://' .. ngx.var.host .. ngx.var.uri
   local req = {
       version = 1.1,
       method = 'POST',
       path = path,
       headers = headers,
       body = 'code=' .. code .. '&redirect_uri=' .. redirectURI .. '&client_id=' .. clientID
     }

   httpc:set_timeout(6000)
   local response, err = httpc:request(req)
   -- ngx.say(type(response))

   if not response then
     msg = "failed to complete request: ", err
     return requestError(ngx.HTTP_UNAUTHORIZED,'unauthorized', msg )
   end
   -- ngx.say("Request Response Status: " .. response.status)
   -- ngx.say("Request Response Reason: " .. response.reason)
   if response.has_body then
     body, err = response:read_body()
     if not body then
       msg = "failed to read post args: " ..  err
       return requestError(ngx.HTTP_UNAUTHORIZED,'unauthorized', msg )
     end
   ngx.header.content_type = 'application/json'
   ngx.say(cjson.encode(body))
   return ngx.exit(ngx.HTTP_OK)
   end


   -- ngx.header.content_type = 'application/json'



   -- --ngx.log(ngx.INFO, "Request Response Status: " .. response.status)
   -- --ngx.log(ngx.INFO, "Request Response Reason: " .. response.reason)

--   if response.has_body then
--     body, err = response:read_body()
--     if not body then
--       msg = "failed to read post args: " ..  err
--       return requestError(ngx.HTTP_UNAUTHORIZED,'unauthorized', msg )
--     end
--     --ngx.log(ngx.INFO, " - response body received and read ")
--     local args = ngx.decode_args(body, 0)
--     if not args then
--       msg = "failed to decode post args: " ..  err
--       return requestError(ngx.HTTP_UNAUTHORIZED,'unauthorized', msg )
--     end
--     --ngx.log(ngx.INFO, " - verify body decoded ")
--     local myDomain = extractDomain( args['me'] )
--     -- local clientDomain = extractDomain( args['client_id'] )
--     --ngx.log(ngx.INFO, "Am I the one who authorized the use of this token?")
--     if ngx.var.domain  ~=  myDomain  then
--       return  requestError(ngx.HTTP_UNAUTHORIZED,'insufficient_scope', 'you are not me')
--     end
--     --ngx.log(ngx.INFO, 'Yep! ' .. ngx.var.domain .. ' same domain as '  .. myDomain   )
--     --ngx.log(ngx.INFO, "Do I have the appropiate CREATE UPDATE scope? ")
--     if args['scope'] ~= 'create update'  then
--       return  requestError(ngx.HTTP_UNAUTHORIZED,'insufficient_scope', ' do not have the appropiate post scope')
--     end
--      --ngx.log(ngx.INFO, "Yep! post scope  equals: " ..  args['scope'])
--     return true
--   else
--     return false
--   end
 end

local function verifyState( state )
return true
end


function _M.verifyToken()
  local HOST = ngx.var.host
  log(ngx.INFO, "Verify Token")
  local msg = ''
  local get, post, files = reqargs()
  if next(get) then
    if not ( get['state']  ) then
      msg = "  - should have get arg: state"
      return requestError(
        ngx.HTTP_NOT_ACCEPTABLE,
        'not accepted',
        msg)
    end
    if not ( get['code'] ) then
      msg = "  - should have get arg: code"
      return requestError(
        ngx.HTTP_NOT_ACCEPTABLE,
        'not accepted',
        msg)
    end
    local code =  get['code']
    local state = get['state']
    log(ngx.INFO,code )
    log(ngx.INFO,state)
   if verifyState( state ) then
     verifyCode( code )
    end
  end

  if next(post) then
     ngx.status  = ngx.HTTP_OK
     ngx.say(cjson.encode(post))
     return ngx.exit(ngx.HTTP_OK)
  end

  if not ( next(post) or next(get) ) then
   msg = "should be a GET query or POST method"
      return requestError(
        ngx.HTTP_NOT_ACCEPTABLE,
        'not accepted',
        msg)
  end

end





return _M
