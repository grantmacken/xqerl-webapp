module namespace routes = 'http://gmack.nz/#routes';

declare variable $routes:XML :=  <root><a>text</a></root>;

declare variable $routes:HTML :=  <html><body><p>hello</p></body></html>;

declare variable $routes:CSV := [ ['headA', 'headB', 'headC'],
                             ['A', 'B', 3], 
                             ['C', 'D', 6] ];

declare variable $routes:CSV_S := '"headA","headB","headC"&#10;"A","B",3&#10;"C","D",6';

declare variable $routes:JSON :=
  map{
    'map' : [
      true(), 123, 'string'
    ]
  };
  
declare variable $routes:JSON_S := '{"map":[true, 123, "string"]}';
  
declare variable $routes:BIN := 'abc123' cast as xs:hexBinary;

declare variable $routes:BIN_S := 'abc123';

declare 
  %rest:path("/gmack.nz/get/xml")
  %rest:GET
  %rest:produces("application/xml")
function routes:get_xml_1(){
  <rest:response>
    <http:response status="200">
      <http:header name="Server" value="xqerl"/>
    </http:response>
    <output:serialization-parameters>
      <output:standalone value='1'/>
    </output:serialization-parameters>
  </rest:response>,
  $routes:XML
};

declare 
  %rest:path("/gmack.nz/get/csv")
  %rest:GET
  %rest:produces("text/plain")
  %output:method("text")
function routes:get_csv_2(){
  csv:serialize($routes:CSV)
};

declare 
  %rest:path("/gmack.nz")
  %rest:GET
  %rest:produces("text/html")
  %output:method("html")
function routes:get_html_3(){
  $routes:HTML
};

declare 
  %rest:path("/gmack.nz/get/json")
  %rest:GET
  %rest:produces("application/json")
  %output:method("json")
function routes:get_json_4(){
  $routes:JSON
};

declare 
  %rest:path("/gmack.nz/get/zip")
  %rest:GET
  %rest:produces("application/octet-stream")
  %output:method("text")
function routes:get_zip_5(){
  $routes:BIN
};

declare 
  %rest:path("/gmack.nz/head/xml")
  %rest:HEAD
function routes:head_xml_7(){};

declare 
  %rest:path("/gmack.nz/head/redirect")
  %rest:HEAD
function routes:head_csv_8(){
  <rest:response>
    <http:response status="302">
      <http:header name="location" value="/gmack.nz/get/html"/>
    </http:response>
  </rest:response>  
};


declare 
  %rest:path("/gmack.nz/post/xml")
  %rest:POST("{$body}")
  %rest:consumes("application/xml", "text/xml")
  %rest:produces("application/xml")
function routes:post_xml_13($body){
  document{
    <got>{
      $body
    }</got>
  }
};

declare 
  %rest:path("/gmack.nz/post/csv")
  %rest:POST("{$body}")
  %rest:consumes("text/csv")
  %rest:produces("application/xml")
function routes:post_csv_22($body){
  document{
    <got>{
      csv:serialize($body)
    }</got>
  }
};

declare 
  %rest:path("/gmack.nz/post/html")
  %rest:POST("{$body}")
  %rest:consumes("text/html")
  %rest:produces("application/xml")
function routes:post_html_30($body){
  document{
    <got>{
      $body
    }</got>
  }
};

declare 
  %rest:path("/gmack.nz/post/json")
  %rest:POST("{$body}")
  %rest:consumes("application/json")
  %rest:produces("application/xml")
function routes:post_json_38($body){
  document{
    <got>{
      map:keys($body)
    }</got>
  }
};

declare 
  %rest:path("/gmack.nz/post/zip")
  %rest:POST("{$body}")
  %rest:consumes("application/octet-stream")
  %rest:produces("application/octet-stream")
function routes:post_zip_47($body){
  $body
};

declare 
  %rest:path("/gmack.nz/post/form")
  %rest:POST
  %rest:consumes("application/x-www-form-urlencoded")
  %rest:produces("application/xml")
  %rest:form-param("message","{$message}", "(no message)")
  %rest:form-param("message2","{$message2}", "(no message)")
function routes:post_form_54($message, $message2){
  document{
    <got>
      <m1>{$message}</m1>
      <m2>{$message2}</m2>
    </got>
  }
};


(: TODO: find out how to do this in an http client :)
declare 
  %rest:path("/gmack.nz/post/form_multi")
  %rest:POST
  %rest:consumes("multipart/form-data")
  %rest:produces("application/xml")
  %rest:form-param("files","{$files}")
function routes:post_form_54a($files){
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
function routes:options_xml_103(){
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
function routes:post_get_1($body, $id){
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
function routes:post_get_1a($id){
  let $uri := 'http://xqerl.org/gmack.nz/restxq/' || $id
  return
  if (doc-available($uri)) then
    doc($uri)
  else
  <rest:response>
    <http:response status="404"/>
  </rest:response>
};

declare 
  %rest:path("/gmack.nz/post/get/doc/{$id}")
  %rest:DELETE
  %updating
function routes:post_get_1b($id){
  let $doc := doc('http://xqerl.org/gmack.nz/restxq/' || $id )
  return
  delete node $doc
};

