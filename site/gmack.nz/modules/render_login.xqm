xquery version "3.1";

module namespace login = "http://gmack.nz/#render_login";


declare
function login:sign-in-form( $map as map(*)) {
element form {
  attribute action { 'https://indielogin.com/auth' },
  attribute method  { 'get' },
  element label {
    attribute for {'url'},
    'Web Address:'
   },:
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
    attribute value {'https://gmack.nz/_callback'}
   },
  element input {
    attribute type {'hidden'},
    attribute name {'state'},
    attribute value {'randomBase64'}
   }
  }
};
