; extends

; Flow `component` / `hook` declarations are not understood by the
; tree-sitter-javascript grammar -- they parse into ERROR / detached nodes
; rather than a real declaration node. We can't fix that from a query, so this
; is a band-aid: color the keyword by name (and best-effort the component name).
; Highlighting only -- indentation, folding and textobjects will NOT treat
; these like `function`. To get that, the grammar itself must be forked.

; the `component` / `hook` keyword
((identifier) @keyword.function
  (#any-of? @keyword.function "component" "hook"))

; `renders` / `export` keywords that the grammar mis-parses as identifiers
; in `[export] component Name(...) renders Type`
((identifier) @keyword
  (#any-of? @keyword "renders" "export"))

; best-effort: `component Name(...)` -> color Name like a function name.
; Relies on the parser's error recovery (adjacent expression statements), so it
; may miss in some surrounding contexts.
(
  (expression_statement (identifier) @_kw)
  .
  (expression_statement (call_expression function: (identifier) @function))
  (#eq? @_kw "component"))

