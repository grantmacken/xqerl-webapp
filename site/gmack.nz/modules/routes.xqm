module namespace routes = 'http://gmack.nz/#routes';
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
(:  test views:  render libs :)
(: import module namespace note = "http://gmack.nz/#render_note"; :)
import module namespace feed = "http://gmack.nz/#render_feed";

declare variable $routes:myCard := map { 
    'card' : map {
       'name' : 'Grant MacKenzie',
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
  %output:method("html")
function routes:home(){
    let $map := $routes:myCard
    return 
    (
    <rest:response>
    <http:response status="200">
      <http:header name="Content-Type" value="text/html; charset=utf-8"/>
    </http:response>
  </rest:response>,
    feed:render( $map )
    )
};

declare
  %rest:path("/gmack.nz/mp")
  %rest:POST('{$body}')
  %rest:query-param("id", "{$id}")
  %updating
function routes:post_get_1($body, $id){
  fn:put($body, 'http://xqerl.org/gmack.nz/restxq/' || $id),
  <rest:response>
    <http:response status="201">
      <http:header name="Location" value="/gmack.nz/post/get/doc/{$id}"/>
    </http:response>
  </rest:response>
};







