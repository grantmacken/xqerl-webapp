module namespace _ = 'http://gmack.nz/#routes';
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: views:  render libs :)
import module namespace note = "http://gmack.nz/#note";
import module namespace feed = "http://gmack.nz/#feed";

declare variable $_:XML :=  <root><a>text</a></root>;

declare variable $_:HTML :=  <html><body><p>hello</p></body></html>;

declare variable $_:CSV := [ ['headA', 'headB', 'headC'],
                             ['A', 'B', 3], 
                             ['C', 'D', 6] ];

declare variable $_:CSV_S := '"headA","headB","headC"&#10;"A","B",3&#10;"C","D",6';

declare variable $_:JSON :=
  map{
    'map' : [
      true(), 123, 'string'
    ]
  };
  
declare variable $_:JSON_S := '{"map":[true, 123, "string"]}';
  
declare variable $_:BIN := 'abc123' cast as xs:hexBinary;

declare variable $_:BIN_S := 'abc123';

declare variable $_:myCard := map { 
    'card' : map {
       'name' : 'Grant Mackenzie',
       'url' : 'https://gmack.nz',
       'uuid' : 'https://gmack.nz',
       'email' : 'mailto:grantmacken@gmail.com',
       'note' : 'somewhere over the rainbow',
       'nickname' : 'grantmacken',
       'adr' : map {
          'street-address' : '8 Featon Ave',
          'locality' : 'Awhitu',
          'country-name' : 'New Zealand'
        }
    }
};


declare 
  %rest:path("/gmack.nz")
  %rest:GET
  %rest:produces("text/html")
  %rest:header-param("Host", "{$host}")
  %output:method("html")
  %output:encoding("UTF-8")
  %output:include-content-type("yes")
function _:home-page($host){
    let $map := map:merge(( $_:myCard, map { "domain" : $host }))
    return 
    feed:render( $map ) 
};


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
let $map := $_:myCard
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

declare 
  %rest:path("/test/get/zip")
  %rest:GET
  %rest:produces("application/octet-stream")
  %output:method("text")
function _:get_zip_5(){
  $_:BIN
};

declare 
  %rest:path("/test/head/xml")
  %rest:HEAD
function _:head_xml_7(){};

declare 
  %rest:path("/test/head/redirect")
  %rest:HEAD
function _:head_csv_8(){
  <rest:response>
    <http:response status="302">
      <http:header name="location" value="/test/get/html"/>
    </http:response>
  </rest:response>  
};


declare 
  %rest:path("/test/post/xml")
  %rest:POST("{$body}")
  %rest:consumes("application/xml", "text/xml")
  %rest:produces("application/xml")
function _:post_xml_13($body){
  document{
    <got>{
      $body
    }</got>
  }
};

declare 
  %rest:path("/test/post/csv")
  %rest:POST("{$body}")
  %rest:consumes("text/csv")
  %rest:produces("application/xml")
function _:post_csv_22($body){
  document{
    <got>{
      csv:serialize($body)
    }</got>
  }
};

declare 
  %rest:path("/test/post/html")
  %rest:POST("{$body}")
  %rest:consumes("text/html")
  %rest:produces("application/xml")
function _:post_html_30($body){
  document{
    <got>{
      $body
    }</got>
  }
};

declare 
  %rest:path("/test/post/json")
  %rest:POST("{$body}")
  %rest:consumes("application/json")
  %rest:produces("application/xml")
function _:post_json_38($body){
  document{
    <got>{
      map:keys($body)
    }</got>
  }
};

declare 
  %rest:path("/test/post/zip")
  %rest:POST("{$body}")
  %rest:consumes("application/octet-stream")
  %rest:produces("application/octet-stream")
function _:post_zip_47($body){
  $body
};

declare 
  %rest:path("/test/post/form")
  %rest:POST
  %rest:consumes("application/x-www-form-urlencoded")
  %rest:produces("application/xml")
  %rest:form-param("message","{$message}", "(no message)")
  %rest:form-param("message2","{$message2}", "(no message)")
function _:post_form_54($message, $message2){
  document{
    <got>
      <m1>{$message}</m1>
      <m2>{$message2}</m2>
    </got>
  }
};


(: TODO: find out how to do this in an http client :)
declare 
  %rest:path("/test/post/form_multi")
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
  %rest:path("/test/options/xml")
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
  %rest:path("/test/post/get")
  %rest:query-param("id", "{$id}")
  %rest:POST('{$body}')
  %updating
function _:post_get_1($body, $id){
  fn:put($body, 'http://xqerl.org/test/restxq/' || $id),
  <rest:response>
    <http:response status="201">
      <http:header name="Location" value="/test/post/get/doc/{$id}"/>
    </http:response>
  </rest:response>
};

declare 
  %rest:path("/test/post/get/doc/{$id}")
  %rest:produces("application/xml")
  %rest:GET
function _:post_get_1a($id){
  let $uri := 'http://xqerl.org/test/restxq/' || $id
  return
  if (doc-available($uri)) then
    doc($uri)
  else
  <rest:response>
    <http:response status="404"/>
  </rest:response>
};

declare 
  %rest:path("/test/post/get/doc/{$id}")
  %rest:DELETE
  %updating
function _:post_get_1b($id){
  let $doc := doc('http://xqerl.org/test/restxq/' || $id )
  return
  delete node $doc
};

