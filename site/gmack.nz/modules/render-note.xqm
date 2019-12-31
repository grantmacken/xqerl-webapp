xquery version "3.1";
module namespace note="http://gmack.nz/#note";

(:
@author Grant MacKenzie
@version 0.0.1

a library for a HTML 5 view
of a stored micropub note
view contains 
 - mf2 formating
 - hyperlinks
   - person
   - feed
   - tags
:)

declare
function note:head( $map  as map(*) ) {
element head {
  element meta { attribute charset { 'utf-8' }},
  element title { $map('title') },
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
    },
  element link {
    attribute href { $map('photo') } ,
    attribute rel { 'apple-touch-icon' }
    },
  element link {
    attribute href { 'https://indieauth.com/auth' },
    attribute rel { 'authorization_endpoint' }
    },
  element link {
    attribute href { 'https://tokens.indieauth.com/token' },
    attribute rel { 'token_endpoint' }
    },
  element link {
    attribute href { $map('mp-endpoint') },
    attribute rel { 'micropub' }
    },
  element link {
    attribute href { '/webmention' },
    attribute rel { 'webmention' }
    }
  }
};

declare
function note:header( $map  as map(*) ) {
  element header {
    attribute title { $map('repo-description') },
    attribute role  { 'banner' },
    element a {
      attribute href {'/'},
      attribute title {'home page'},
      $map('card')('name')
    }
  }
};

declare
function note:content( $map  as map(*), $node as node()) {
 element article {
  attribute class { $map('post-type') },
  element a {
    attribute class {'u-url'},
    attribute href {$node/entry/url/string()},
    attribute rel {'bookmark'},
    attribute title {'published ' || $map('post-type') },
    element img {
      attribute width {'16'},
      attribute height {'16'},
      attribute alt { $map('post-type')},
      attribute src { '/icons/' || $map('post-type') }
      },
    element time {
      attribute class { 'dt-published' },
      attribute datetime { $node/entry/published/string() },
        format-dateTime(xs:dateTime($node/entry/published/string()) , "[D1o] of [MNn] [Y]", "en", (), ())
      }
    },
     element div {
      attribute class { 'e-content p-name' },
      if ( exists($node/entry/content/html/node()) ) then ($node/entry/content/html/node()) 
      else if  ( exists($node/entry/content/value/text()) ) then ($node/entry/content/value/string()) 
      else($node/entry/content/text()) 
      },
      'authored by',
      element a {
        attribute href {'/'},
        attribute class {'p-author h-card'},
        $map('card')('name')
      }
    }
};

declare
function note:tags( $node as node()) {
  if ( $node/entry/syndication ) then (
  element small {'tags  [ ' || count($node/entry/category) || ' ]&#10;'},
  element ul {
    attribute class {'vertical_list'},
    for-each(  $node/entry/category  , function($a) {
      element li { 
        element a {
          attribute href { concat('/tags/', $a) }
          , $a }
          }
      })
    }
  )
 else ()
};

declare
function note:syndication( $node as node()) {
 if ( $node/entry/syndication ) then (
  element small {'elsewhere  [ ' || count($node/entry/syndication) || ' ]&#10;'},
  element ul {
    attribute class {'vertical_list'},
    for-each(  $node/entry/syndication  , function($a) {
      element li {
        element a {
          attribute href { $a/string() },
           note:syndicatedTo($a/string()  )
          }
          }
      })
    }
  )
 else ()
};

declare
function note:syndicatedTo( $url as xs:string ) as xs:string   {
 if (starts-with( $url, 'https://twitter.com' )) then ('twitter')
 else ($url)
};


declare
function note:footer( $map  as map(*), $node as node() ) {
  element footer {
    attribute title { 'page footer' },
    attribute role  { 'contentinfo' },
    $node => fn:serialize()   
        
  }
};

declare
function note:render( $map as map(*), $node as node()) {
  (:
  let $title :=  'note ' || $node/entry/uid/string()
  let $myPhoto := $map('card-photo')
  let $mpEndpoint := $map('micropub-endpoint')
  :)
 element html {
   note:head( $map ),
   element body {
     attribute class {'h-entry'},
     note:header( $map ),
     note:content( $map, $node),
     element aside {(
       note:tags( $node ),
       note:syndication( $node )
       )},
     note:footer( $map, $node )
   }
 }
};
