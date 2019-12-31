module namespace _ = 'http://gmack.nz/#routes';

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: views:  render libs :)
import module namespace note = "http://gmack.nz/#note";
import module namespace feed = "http://gmack.nz/#feed";

(: micropub CRUD ops :)
import module namespace mp  = "http://gmack.nz/#mp";

declare variable $_:card := map { 
    'name' : 'Grant Mackenzie',
    'url' : 'https://gmack.nz'
    } ;

declare 
  %rest:path("/gmack.nz")
  %rest:GET
  %output:method("html")
  %output:indent("yes")
  %output:encoding("UTF-8")
  %output:include-content-type("yes")
  %rest:header-param("Host", "{$host}")
function _:home($host){
    let $map := map { "domain" : $host }
    return 
    feed:render( $map ) 
};


(: 
 detirmine   post-type 
 https://indieweb.org/post-type-discovery
:)

declare 
  %rest:path("/gmack.nz/archive/{$uid}")
  %rest:GET
  %output:method("html")
  %output:indent("yes")
  %output:encoding("UTF-8")
  %output:include-content-type("yes")
  %rest:header-param("Host", "{$host}")
function _:archive($uid, $host){
let $doc := fn:doc( 'http://' || $host || '/archive/' || $uid )
let $map := map {} => 
            map:put( 'card', $_:card )
return
  if ( $doc instance of document-node() )
  then (
      if ( $doc/entry/category  =  "post:note"  )
      then ( note:render( $map  => map:put('post-type','note'),
                          fn:doc( 'http://' || $host || '/archive/' || $uid ))
      ) else (
        <rest:response>
            <http:response status="404"/>
        </rest:response>,
        element div {'TODO' } 
      )
  )
  else (
    <rest:response>
       <http:response status="404"/>
    </rest:response>,
    element div {'TODO' } 
  )
};




(:
Micropub Server
A Micropub Server is an implementation that can create and optionally edit and 
delete posts given a Micropub request.
https://www.w3.org/TR/micropub/
:)

(: micropub FORM endpoint :)
declare 
  %rest:path("/gmack.nz/micropub")
  %rest:POST
  %rest:consumes("application/x-www-form-urlencoded")
  %output:method("xml")
  %output:indent("yes")
  %output:omit-xml-declaration("yes")
  %rest:form-param("h","{$h}", "")
  %rest:form-param("action","{$action}", "")
  %rest:form-param("url","{$url}", "")
  %rest:form-param("content","{$content}", "")
  %rest:header-param("UTC", "{$utc}")
  %rest:header-param("Host", "{$host}")
function _:mp( $h, $content, $action, $url, $utc, $host  ) {
for $prop in ( $h , $action )
    return switch ($prop)
    case "entry"
        return 
        map { 
            'utc' : $utc,
            'host' : $host,
            'content' : $content
        } =>  mp:createNote()
    case "delete"
        return
        map { 
            'utc' : $utc,
            'host' : $host,
            'url' : $url
        } =>  mp:deleteEntry()
    case "undelete"
        return
        map { 
            'utc' : $utc,
            'host' : $host,
            'url' : $url
        } =>  mp:undeleteEntry()
    default
        return ()
};

(: micropub JSON endpoint :)
declare 
  %rest:path("/gmack.nz/micropub")
  %rest:POST("{$body}")
  %rest:consumes("application/json")
  %rest:produces("plain/text")
function _:mpJSON($body){
   if ( map:contains($body,'action') ) then (
     switch ( map:get($body,'action') )
     case "delete" return map { }
     case "undelete" return map { }
     case "replace" return map { }
     default return  ()
     )
   else if ( map:contains($body,'type') ) then ()
   else ()
};
(:


application/xml
for $prop in ( map:keys($body) )
    return switch ($prop)
    case "action"
        return (
          map {}
        )
     default
     return ()
:)

(: TODO: find out how to do this in an http client :)
declare 
  %rest:path("/gmack.nz/post/form_multi")
  %rest:POST
  %rest:consumes("multipart/form-data")
  %rest:produces("application/xml")
  %rest:form-param("files","{$files}")
function _:post_form_54a($files){
  document{
    <got>{
      for $name in map:keys($files)
      return
      <file>
        <name>{$name}</name>
        <content>{ $files($name) }</content>
      </file>
    }</got>
  }
};

declare 
  %rest:path("/gmack.nz/options/xml")
  %rest:OPTIONS
function _:options_xml_103(){
  <rest:response>
    <http:response status="200">
      <http:header name="Allow" value="GET,HEAD"/>
    </http:response>
  </rest:response>,
  'empty?'
};

declare 
  %rest:path("/gmack.nz/post/get")
  %rest:query-param("id", "{$id}")
  %rest:POST('{$body}')
  %updating
function _:post_get_1($body, $id){
  fn:put($body, 'http://xqerl.org/gmack.nz/restxq/' || $id),
  <rest:response>
    <http:response status="201">
      <http:header name="Location" value="/gmack.nz/post/get/doc/{$id}"/>
    </http:response>
  </rest:response>
};

declare 
  %rest:path("/gmack.nz/post/get/doc/{$id}")
  %rest:produces("application/xml")
  %rest:GET
function _:post_get_1a($id){
  let $uri := 'http://xqerl.org/gmack.nz/restxq/' || $id
  return
  if (doc-available($uri)) then
    doc($uri)
  else
  <rest:response>
    <http:response status="404"/>
  </rest:response>
};



