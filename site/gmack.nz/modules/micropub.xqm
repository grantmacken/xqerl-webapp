xquery version "3.1";
module namespace mp  = "http://gmack.nz/#micropub";
import module namespace newBase60 = "http://gmack.nz/#newBase60";
(:~

:)
declare
  %updating
function mp:deleteEntry( $map  as map(*) ) {
let $uid    := $map('url') => substring-after( $map('host') || '/' )
let $target := fn:doc('http://' || $map('host') || '/archive/' ||  $uid)/*
let $source :=  <post-status>deleted</post-status>
return (
  <rest:response>
    <http:response status="204"/>
  </rest:response>,
  if ($target/post-status/text()) then (
    replace node $target/post-status with $source
    )
  else (
    insert node $source into $target
    )
  )
};

declare
  %updating
function mp:undeleteEntry( $map  as map(*) ) {
let $uid    := $map('url') => substring-after( $map('host') || '/' )
let $target := fn:doc('http://' || $map('host') || '/archive/' ||  $uid)/*
let $source :=  <post-status>published</post-status>
return (
  <rest:response>
    <http:response status="204"/>
  </rest:response>,
  if ($target/post-status/text()) then (
    replace node $target/post-status with $source
    )
  else (
    insert node $source into $target
    )
  )
};




(:
https://github.com/indieweb/micropub-extensions/issues/19
post-status: [ 'published', 'draft', 'deleted' ] 
  if ( empty($doc/entry/post-status/text()) ) then (
   insert node element post-status { "published" } 
   after fn:doc($dbURI)/entry/published
    ) 
  else( 
 
    )
:)

declare
  %updating
function mp:createNote( $map  as map(*) ) {
let $uid := (
    xs:dateTime( $map('utc') ) => newBase60:dateToInteger() => newBase60:encode(),
    xs:dateTime( $map('utc') ) => newBase60:timeToInteger() => newBase60:encode()
    ) => string-join('')
let $location := 'https://' || $map('host') || '/' || $uid
let $dbURI    := 'http://' || $map('host') || '/archive/' || $uid 
let $published :=
    xs:dateTime( $map('utc') ) => 
    fn:adjust-dateTime-to-timezone(xs:dayTimeDuration('PT13H')) =>
    format-dateTime("[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01][Z]")
return (
  <rest:response>
    <http:response status="201">
      <http:header name="Location" value="{$location}"/>
    </http:response>
  </rest:response>,
  document {
    element entry {
      element published { $published },
      element post-status { "published" },
      element uid { $uid },
      element url { $location },
      element content { $map('content') },
      element category { 'post:note' }
    }
  }  =>  fn:put($dbURI)
  )

};
