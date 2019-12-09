local _M = {}

local ffi = require("ffi")
local c = ffi.load("libcmark")
ffi.cdef[[
  /*  Simple Interface */
  char *cmark_markdown_to_html(const char *text, size_t len, int options);

  typedef struct cmark_node cmark_node;
  typedef struct cmark_parser cmark_parser;
  typedef struct cmark_iter cmark_iter;
  typedef struct cmark_mem {
    void *(*calloc)(size_t, size_t);
    void *(*realloc)(void *, size_t);
    void (*free)(void *);
  } cmark_mem;

  /* Version information */
  int cmark_version(void);
  const char *cmark_version_string(void);

  /* ## Parsing */
  cmark_parser *cmark_parser_new(int options);
  cmark_parser *cmark_parser_new_with_mem(int options, cmark_mem *mem);
  void cmark_parser_free(cmark_parser *parser);
  void cmark_parser_feed(cmark_parser *parser, const char *buffer, size_t len);
  cmark_node *cmark_parser_finish(cmark_parser *parser);
  cmark_node *cmark_parse_document(const char *buffer, size_t len, int options);

  /* ## Rendering */
  char *cmark_render_xml(cmark_node *root, int options);
  char *cmark_render_html(cmark_node *root, int options);
  char *cmark_render_man(cmark_node *root, int options, int width);
  char *cmark_render_commonmark(cmark_node *root, int options, int width);
  char *cmark_render_latex(cmark_node *root, int options, int width);

  ]]

local options = {
CMARK_OPT_DEFAULT  = 0,
CMARK_OPT_SOURCEPOS = 1,
CMARK_OPT_HARDBREAKS = 2,
CMARK_OPT_SAFE = 32,
CMARK_OPT_NOBREAKS = 4,
CMARK_OPT_VALIDATE_UTF8 = 16,
CMARK_OPT_SMART= 8
}


-- Simple Interface
local function markdownToHtml( text )
  local markdown_to_html  = c.cmark_markdown_to_html
  return
  ffi.string(markdown_to_html(text, string.len(text),0))
end

-- Version information
local function version( )
  local ver =  c.cmark_version_string()
  --  ver is typeof CDATA
  return
  ffi.string(ver, ffi.sizeof(ver))
end


--  Parsing
local function parseString( s )
  local parse_document  = c.cmark_parse_document
  return parse_document(s, string.len(s), 0)
end

--  Rendering
local function renderHTML( doc )
  local render_html  = c.cmark_render_html
  local r = render_html(doc, 0)
  return
  ffi.string(r)
end

local function renderXML( doc )
  local r = c.cmark_render_xml(doc, 0)
  return
  ffi.string(r)
end

local function renderCommonMark( doc )
  local r = c.cmark_render_commonmark(doc, 0, 80)
  return
  ffi.string(r)
end

function _M.convertToXML()
  ngx.req.read_body()
  local data = ngx.req.get_body_data()
  ngx.log(ngx.INFO, ' - got sent body data' )
  local doc = parseString( data )
  local xmlDoc = renderXML( doc )
  ngx.say(xmlDoc)
end

_M.version = version()
return _M
