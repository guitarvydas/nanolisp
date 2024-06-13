package smalllisp
import uni "core:unicode/utf8"

MemSize :: 256+1
MemMiddle :: MemSize / 2
MemPtr :: i16
Ptr :: MemPtr
EOF :: 0xff // not a legal UTF-8 rune (UTF-8 runes must begin with either 0xxxxxxx, 110xxxxx, 1110xxxx or 11110xxx)
lisp_nil :: 0 // > nil --> list cells, < nil --> atoms
offset :: MemMiddle

CARsize :: 1
CDRsize :: 1
CellLength :: CARsize + CDRsize
CDRoffset :: CARsize

FIRSTAtom :: 0
FIRSTList :: -2

mem := [MemSize]Ptr{}

Sexpr :: MemPtr
Alist :: MemPtr

// atom: +ve indices, car == 1 byte (character), cdr == Ptr
// list: -ve indices,  car == Ptr, cdr == Ptr
// where Ptr might be 0, meaning nil

is_Nil ::proc (p : Ptr) -> bool {
    return p == lisp_nil
}

is_Atom :: proc (p : Ptr) -> bool {
    return (p > 0)
}

within_mem_boundaries :: proc (p : Ptr) -> bool {
    x := p + offset
    return x >= 0 && x < len (mem)
}

rune_at :: proc (p : MemPtr) -> rune {
    return cast (rune) mem [p]
}
