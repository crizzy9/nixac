" Syntax highlighting for bufferline-rearrange buffer

if exists("b:current_syntax")
  finish
endif

" Match comments (instructions)
syn match BufferlineRearrangeComment "^#.*$"

" Match buffer number
syn match BufferlineRearrangeNumber "^\d\+"

" Match separator
syn match BufferlineRearrangeSeparator ":" contained

" Match buffer name
syn match BufferlineRearrangeName ":.*$" contains=BufferlineRearrangeSeparator

" Define highlighting
hi def link BufferlineRearrangeComment Comment
hi def link BufferlineRearrangeNumber Number
hi def link BufferlineRearrangeSeparator Delimiter
hi def link BufferlineRearrangeName String

let b:current_syntax = "bufferline-rearrange"
