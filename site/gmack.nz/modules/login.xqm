xquery version "3.1";
module namespace login   = "http://gmack.nz/#login";
declare namespace binary = "http://expath.org/ns/binary";
declare namespace db     = "http://xqerl.org/modules/database";
declare namespace http   = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace random = "http://xqerl.org/modules/random";
declare namespace rest   = "http://exquery.org/ns/restxq";
import module namespace newBase60  = "http://gmack.nz/#newBase60";

declare
variable $login:items := map {
       'dbSecretsURL'   : 'http://xq/secrets.xml',
       'dbSessionURL'   : 'http://xq/session.xml',
       'dbStateURL'     : 'http://xq/state.xml',
       'ghAuthorizeURL' : 'https://github.com/login/oauth/authorize',
       'ghTokenURL'     : 'https://github.com/login/oauth/access_token',
       'ghAPI'          : 'https://api.github.com',
       'ghHeaderAccept'    : 'application/vnd.github.v3+json',
       'ghHeaderUserAgent' : 'application/vnd.github.v3+json',
       'ghHeaderTimeZone'  : 'Pacific/Auckland',
       'ghScope'        : 'user',
       'myState'        : 'myRandomState'
 };

declare
variable $login:ok :=
    <rest:response>
    <http:response status="200">
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>;

declare
variable $login:state :=
    <rest:response>
    <http:response status="200">
      <http:header name="State" value="xxx"/>
    </http:response>
  </rest:response>;


declare
variable $login:unauthorized :=
  <rest:response>
    <http:response status="401" />
  </rest:response>;

declare
variable $login:request :=
    <http:request method='POST' override-media-type='application/xml'>
      <http:header name='Accept' value='application/xml'/>
      <http:body media-type='application/x-www-form-urlencoded'/>
    </http:request>;


declare
variable $login:form :=
element form {
  attribute action { 'https://login.gmack.nz/auth' },
  attribute method  { 'get' },
  element label {
    attribute for {'url'},
    'Web Site Domain:'
   },
  element input {
    attribute id {'url'},
    attribute type {'text'},
    attribute name {'domain'},
    attribute value {'gmack.nz'},
    attribute placeholder { 'gmack.nz' }
   },
  element p {
    element button {
      attribute type {'submit'},
      'Log In'
    }
  }
};

declare
function login:err( $msg as xs:string ) {(
  $login:unauthorized,
  element html {
    attribute lang {'en'},
    login:head( 'token callback'),
    element body {
      element h1 { 'login error' },
      element p { $msg }
    }
  } 
)};



declare
function login:obtainTokenBody( $state, $code) {
'client_id=' || $login:items('ghClientID') ||
 '&amp;client_secret=' || $login:items('ghClientSecret') ||
 '&amp;code=' || $code ||
 '&amp;state' || $state
};

declare
function login:dtStamp() {
 let $dateTime := current-dateTime() => adjust-dateTime-to-timezone(xs:dayTimeDuration('PT13H'))
 let $bDate :=  $dateTime => newBase60:dateToInteger() => newBase60:encode()
 let $bTime := $dateTime => newBase60:timeToInteger() =>  newBase60:encode()
 let $dtStamp := concat( string($bDate) , string($bTime) )
 return $dtStamp
};



declare
function login:ghAuth( $state , $client_id  ) {
  (
  $login:ok,
  element html {
    attribute lang {'en'},
    login:head( 'TODO ' ),
    element body {
      login:header( 'Grant Mackenzie' ),
      element article {
        element p {  'state : [ ' || $state || ' ]' },
        element p { 
          element a {
            attribute href {
              $login:items('ghAuthorizeURL') || 
              '?scope='         || $login:items('ghScope')   ||
              '&amp;client_id=' || $client_id ||
              '&amp;state='     || $state },
            'request github authorization'
            }
          }
        },
        element footer { 'my footer'}
      }
    }
)};

declare
  %updating
  %rest:path("/login.gmack.nz/github")
  %rest:GET
  %rest:produces("text/html")
function login:auth() {
  let $m := $login:items
  let $docAvailable := doc-available($m('dbSecretsURL'))
  (: TODO try catch throw :)
  let $doc := doc($m('dbSecretsURL'))
  let $owner := element owner {''}
  let $state := element state { random:uuid() }
  let $noState := empty( $doc//github/state )
  return (
  if ( $noState ) then (
      insert node $state into $doc//github
    ) else (),
  login:ghAuth( $doc//github/state/string(), $doc//github/client_id/string() )
)};




declare 
function login:ghTokenRequest( $code, $state, $clientID, $clientSecret ) {
  let $resp := http:send-request(
        <http:request method='POST'>
          <http:header name='Accept' value='application/xml'/>
          <http:body media-type='application/x-www-form-urlencoded'/>
        </http:request>, $login:items('ghTokenURL'),
      'client_id=' || $clientID ||
      '&amp;client_secret=' || $clientSecret ||
      '&amp;code=' || $code ||
      '&amp;state' || $state
      )
  let $headers := $resp[1]
  let $body := $resp[2]
  return $body
};


declare 
function login:ghUserRequest( $token ) {
  let $userURL := 'https://api.github.com/user'
  let $resp := http:send-request(
        <http:request method='GET'>
          <http:header name='Accept' value='application/vnd.github.v3+json'/>
          <http:header name='Authorization' value='{$token}'/>
        </http:request>,
        $userURL
      )
  let $map := $resp[2]
  return $map
};

declare 
function login:ghUserDetails( $map, $ghClientID ) {(
  <rest:response>
    <http:response status="200">
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  element html {
    attribute lang {'en'},
    login:head( 'github user '),
    element body {
      element h1 { 'github user details' },
      element p {  'login [ '  ||  $map('login') || ' ]' },
      element p {  'email [ '  ||  $map('email') || ' ]' },
      element p {  'blog [ '   ||  $map('blog') || ' ]' },
      element p {  'avatar_url [ ' ||  $map('avatar_url') || ' ]' },
      element p {
        element a {
          attribute href { 'https://github.com/settings/connections/applications/' ||  $ghClientID  },
          'review access'
        }
      },
      element p {
        element a {
          attribute href { '?action=set_cookie&amp;card=' || $map('login') },
          'set session cookie'
        },
        text { ': session cookies expire when a session closes'}
      }
    }
  }
)};


declare
  %updating
  %rest:path("/login.gmack.nz/gh")
  %rest:GET
  %rest:query-param("state", "{$state}", "nope")
  %rest:query-param("code", "{$code}", "nope")
  %rest:produces("text/html")
function login:gh( $state, $code ) {
  let $m := $login:items
  let $doc := doc($m('dbSecretsURL'))
  let $myState := $doc//github/state/string()
  return (
  if ( $state eq $myState ) then ( 
     let $clientID := $doc//github/client_id/string()
     let $clientSecret :=  $doc//github/client_secret/string()
     let $tokenBody := login:ghTokenRequest( $code, $state, $clientID, $clientSecret )
     return (
      if ( $tokenBody instance of document-node() ) then (
        if ( $tokenBody/OAuth/error/text() ) then ( login:err( $tokenBody/OAuth/error_description/string() ))
        else ( (: good now fetch user details from github :)
          let $token := 'token ' || $tokenBody//access_token/string()
          let $map := login:ghUserRequest( $token )
          let $login := 
            element card {
              element owner { $map('login') },
              element email { $map('email') },
              element blog  { $map('blog') },
              element auth  { $tokenBody//access_token/string() }
            }
          return (
            insert node $login into $doc//github,
            login:ghUserDetails( $map, $clientID ) 
            )
          )
        )
      else ( login:err( ' did not get document node' ))
     )
    )
  else ( login:err( 'sent state does not match recieved state' ) )
)};



declare
  %rest:path("/login.gmack.nz")
  %rest:query-param("user", "{$user}", "nope")
  %rest:GET
function login:set_user( $user ) {

  let $m := $login:items
  let $doc := doc($m('dbSecretsURL'))

  (: $state := doc($m('dbStateURL')) :)
  let $dateStamp := login:dtStamp() 
  return (
  if (  $user eq 'nope' ) then (
   $login:ok,
    element html {
      attribute lang {'en'},
      login:head( 'TODO remove ' ),
      element body {
       $login:form
      }
    }
  )
  else (
    $login:ok,
    element html {
      attribute lang {'en'},
      login:head( 'log in page' ),
      element body {
        element h1 { 'logged in' },
        element p {  'user: [ '    || $user || ' ]' }
      }
    }
  )
)};

declare
  %rest:path("/login.gmack.nz/gh_user/{$user}")
  %rest:GET
  %output:method("html")
function login:user( $user ) {
  let $m := $login:items
  let $doc := doc($m('dbSecretsURL'))
  let $m := $login:items 
  let $ghOwnerExists := exists($doc//github/card/owner[ . = $user ]/text())
  return ( $login:ok,
  element html {
    attribute lang {'en'},
    login:head( 'log in page' ),
    element body {  
      element header {
        element h1 { 'logged in: ' || $user }
        },
      element main {
        element p {  'todo: [ '    || '$state' || ' ]' }
        },
      element footer {
        'TODO!'
        }
      }
    }
)};


(: Set-Cookie: user=$res;  Domain=gmack.nz; SameSite=Strict :)


declare
  %rest:path("/login.gmack.nz/admin")
  %rest:GET
  %rest:query-param("user", "{$user}", "nope")
  %rest:query-param("action", "{$action}", "nope")
  %rest:produces("text/html")
function login:admin( $user, $action ) {
  let $m := $login:items
  let $doc := doc($m('dbSecretsURL'))
  let $gh    :=   $doc//github[1]
  let $ghOwner := $gh/card[1]/owner/string()
  let $ghClientID := $gh/client_id/string()
  return (
  if ( $action eq 'set_cookie' ) then (
  <rest:response>
    <http:response status="200">
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response> )
  else ( $login:ok ) ,
  element html {
    attribute lang {'en'},
    login:head( 'admin'),
    element body {
      element h1 { 'admin'},
      element p { 
        element a {
          attribute href { 'https://github.com/settings/connections/applications/' ||  $ghClientID },
          'review access'
        }
      },
      element p {  
        element a {
          attribute href { '?action=set_cookie&amp;card=' || $ghOwner },
          'set cookie'
        }
      },
      element p {  'user: '   ||  $user },
      element p {  'action: '   ||  $action },
      element p {  'owner: '   ||  $gh/card[1]/owner },
      element p {  'email: '   ||  $gh/card[1]/email/string() },
      element p {  'website: ' ||  $gh/card[1]/blog/string() }
    }
  }
)};

declare
  %rest:path("/login.gmack.nz/user/{$user}")
  %rest:GET
  %output:method("html")
function login:admin( $user ) {
  let $m := $login:items
  let $doc := doc($m('dbSecretsURL'))
  let $gh    :=   $doc//github[1]
  let $ghClientID := $gh/client_id/string()
  return (
  <rest:response>
    <http:response status="200">
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
  element html {
    attribute lang {'en'},
    login:head( 'admin'),
    element body {
      element h1 { 'admin'},
      element p { $gh/card/owner },
      element p { $gh/state/text() },
      element p { $ghClientID },
      element p { 
        element a {
          attribute href { 'https://github.com/settings/connections/applications/' ||  $ghClientID },
          'review access'
        }
      }
    }
  }
)};


declare
function login:head( $title ) {
element head {
  element meta { attribute charset { 'utf-8' }},
  element title { $title },
  element meta {
    attribute name { 'viewport' },
    attribute content { 'width=device-width, initial-scale=1' }
    },
  element link {
    attribute href { '/styles' },
    attribute rel { 'Stylesheet' },
    attribute type { 'text/css' }
    },
  element link {
    attribute href { '/icons/compose' },
    attribute rel { 'icon' },
    attribute type { 'image/svg+xml' }
    }
  }
};

declare
function login:header( $title ) {
element header { $title }
};

