xquery version "3.1";
module namespace feed = "http://gmack.nz/#render_feed";
declare
function feed:getKindOfPost( $entry ) {
    if ( $entry/category[contains(.,'post:')][1] )
    then ( $entry/category[contains(.,'post:')][1] => substring-after('post:'))
    else ( 'note' )
};

declare
function feed:getTags( $entry ) {
  $entry/category[not(contains(.,'post:'))]
};

declare
function feed:head( $map as map(*)) {
element head {
  element meta { attribute charset { 'utf-8' }},
  element title { $map('kind') || ' for ' || $map('domain') },
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
    attribute href { $map('card-photo') } ,
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
    attribute href { $map('micropub-endpoint') },
    attribute rel { 'micropub' }
    }
  }
};

declare
function feed:header( $map as map(*)) {
element header {
(:
  attribute title { $map('repo-description') },
  attribute role  { 'banner' },
:)
  feed:rep-card( $map )
}

};

declare
function feed:sign-in-form( $map as map(*)) {
element form {
  attribute action { 'https://indielogin.com/auth' },
  attribute method  { 'get' },
  element label {
    attribute for {'url'},
    'Web Address:'
   },
  element input {
    attribute id {'url'},
    attribute type {'text'},
    attribute name {'me'},
    attribute placeholder { $map('url') }
   },
  element p {
    element button {
      attribute type {'submit'},
      'Sign In'
    }
  },
  element input {
    attribute type {'hidden'},
    attribute name {'client_id'},
    attribute value {$map('url')}
   },

  element input {
    attribute type {'hidden'},
    attribute name {'redirect_uri'},
    attribute value {'https://gmack.nz/_login'}
   },

  element input {
    attribute type {'hidden'},
    attribute name {'state'},
    attribute value {'skdsldslmdmdaaaqwpomnzx'}
   }
  }
};

declare
function feed:rep-card( $map as map(*)) {
element div {
  attribute id {'rep-card'},
  attribute class {'h-card'},
  element a {
    attribute class { 'u-url' },
    attribute href { $map('url') },
    element figure {
      element img {
        attribute width { '16' },
        attribute height { '16' },
        attribute alt { 'user' },
        attribute src { '/icons/user' }
      },
      element figcaption {
        attribute class { 'nameAsHeader p-name' },
         $map('name') 
      }
    }
   },
   element a {
     attribute class { 'u-email' },
     attribute href { $map('email') },
     element figure {
       attribute class { 'contact-info' },
       element img {
         attribute width { '16' },
         attribute height { '16' },
         attribute alt { 'email' },
         attribute src { '/icons/mail' }
       },
       element figcaption { $map('email') }
     }
   },
 (: address :)
  element div {
    element figure {
      attribute class { 'h-adr' },
      element img {
      attribute width { '16' },
      attribute height { '16' },
      attribute alt { 'geo location' },
      attribute src { '/icons/geolocation' }
      },
      element figcaption {
        element span {
            attribute class { 'p-street-address'  },
            $map('adr')('street-address')
        }, ', ' ,
      element span {
            attribute class { 'p-locality'  },
            $map('adr')('locality' )
        }, ', ',
      element span {
            attribute class { 'p-country-name'  },
            $map('adr')('country-name')
        }
      }
    }
  },
  element div {
    attribute id { 'link-to-profiles' },
    element p {'my profile links'},
     element a {
       attribute href {  'https://github.com/' || $map('nickname') },
       attribute rel {  'me' },
       element figure {
         attribute class { 'contact-info' },
         element img {
           attribute width { '16' },
           attribute height { '16' },
           attribute alt { 'github icon' },
           attribute src { '/icons/github' }
         },
         element figcaption {  $map('nickname') || ' on github'}
       }
     },
     element a {
       attribute href { 'https://twitter.com/' || $map('nickname') },
       attribute rel {  'me' },
       element figure {
         attribute class { 'contact-info' },
         element img {
           attribute width { '16' },
           attribute height { '16' },
           attribute alt { 'github icon' },
           attribute src { '/icons/twitter' }
         },
         element figcaption { '@' || $map('nickname') || ' on Twitter' }
       }
     }
    }
  }
};


declare
function feed:footer( $map as map(*)) {
  element footer {
    attribute title { 'page footer' },
    attribute role  { 'contentinfo' },
    element a {
      attribute href {'/'},
      attribute title {'home page'},
      $map('url') => substring-after('//')
    },
    ' is the website',
    'owned, authored and operated by ' ,
    element a {
      attribute href { $map('url')},
      attribute title {'author'},
      $map('name')
    }
  }
};



declare
function feed:recent-entries( $map as map(*)) {
    for $entry at $i in fn:collection('http://gmack.nz/archive')/*
    order by xs:dateTime($entry/published) descending
    let $kindOfPost := feed:getKindOfPost($entry)
    let $tags :=   feed:getTags($entry)

    return
      element article {
        attribute class {'h-entry '  || $kindOfPost },
        element a {
          attribute class {'u-url'},
          attribute href {$entry/url/string()},
          attribute rel {'bookmark'},
          attribute title {'published ' || $kindOfPost },
          element img {
            attribute width {'16'},
            attribute height {'16'},
            attribute alt { $kindOfPost },
            attribute src { '/icons/' || $kindOfPost }
            },
          element time {
            attribute class { 'dt-published' },
            attribute datetime { $entry/published/string() },
             format-dateTime(xs:dateTime($entry/published/string()) , "[D1o] of [MNn] [Y]", "en", (), ())
            }
          },
          switch ( $kindOfPost )
          case "note" return
                      element p {
                      attribute class { 'e-content' },
                      $entry/content/text() }
          case "article" return ()
          default    return ()
        }
 };


declare
function feed:render( $map as map(*) ) {
  element html {
    attribute lang {'en'},
    feed:head( $map ),
    element body {
      feed:header( $map('card') ),
      element main {
        attribute class {'h-feed'},
        element article { 'hello' }
        (: feed:recent-entries( $map ) :)
      },
      element aside {
        "TODO"
        (:feed:sign-in-form( $map('card') ) :)
        },
      feed:footer( $map('card') )
      }
    }
};
