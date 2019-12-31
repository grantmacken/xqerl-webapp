xquery version "3.1";
module namespace feed = "http://gmack.nz/#feed";
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
  attribute title { $map('repo-description') },
  attribute role  { 'banner' },
  element a {
    attribute href {'.'},
    attribute title {'home page'},
    $map('card-name')
   }
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
    attribute placeholder {'https://gmack.nz'}
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
    attribute value {'https://gmack.nz'}
   },

  element input {
    attribute type {'hidden'},
    attribute name {'redirect_uri'},
    attribute value {'https://gmack.nz/_login'}
   },

  element input {
    attribute type {'hidden'},
    attribute name {'state'},
    attribute value {'jwiusuerujs'}
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
      $map('domain')
    },
    ' is the website',
     '(v' || $map('pkg-version') || ')',
    'owned, authored and operated by ' ,
    element a {
      attribute href {'.'},
      attribute title {'author'},
      $map('card-name')
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
      feed:header( $map ),
      element main {
        attribute class {'h-feed'},
        feed:recent-entries( $map )
      },
      element aside { ()
        },
      feed:footer( $map )
      }
    }
};
