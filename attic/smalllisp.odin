package smalllisp

import "core:fmt"
import "core:strings"
import "core:os"



Set :: proc (p : Ptr, v : Ptr) { mem [p + offset] = v }
Get :: proc (p : Ptr) -> Ptr { return mem [p + offset] }
Car :: proc (p : Ptr) -> Ptr { return Get (p) }
Cdr :: proc (p : Ptr) -> Ptr { return Get (p + 1) }
List :: proc (p : Ptr) -> bool { return p >= offset }
Atom :: proc (p : Ptr) -> bool { return p < offset }
Null :: proc (p : Ptr) -> bool { return p == offset }


nextAtom : Ptr = FIRSTAtom
nextList : Ptr = FIRSTList

GetByte :: proc (p : Ptr) -> byte {
    return cast (byte) mem [p + offset]
}

SetByte :: proc (p : Ptr, v : byte) {
    mem [p + offset] = cast (Ptr) v
}

GetRune :: proc (p : Ptr) -> rune {
    return cast (rune) mem [p + offset]
}

AllocAtom :: proc () -> Ptr {
    fmt.assertf (within_mem_boundaries (nextAtom), "out of (atom) memory\n")
    r := nextAtom
    nextAtom = nextAtom + CellLength
    return r
}

AllocList :: proc () -> Ptr { 
    fmt.assertf (within_mem_boundaries (nextList), "out of (list) memory\n")
    r := nextList
    nextList = nextList - CellLength
    return r
}

Cons :: proc (left : Ptr, right : Ptr) -> Ptr {
    p := AllocList ()
    Set (p, left)
    Set (p + 1, right)
    return p
}

kNil : i16 // 0
kFalse : i16 // 0
kTrue : i16 // 6
kEq : i16 // 8
kCar : i16 // 12
kCdr : i16 // 18
kAtom : i16 // 24
kCond : i16 // 32
kCons : i16 // 40
kQuote : i16 // 48

initialize :: proc () {
    for i := 0 ; i < len (mem) ; i += 1 {
	mem [i] = 0
    }
    nextAtom  = FIRSTAtom
    nextList  = FIRSTList
    kNil = nextAtom
    install_new_atom ("nil")
    kTrue = nextAtom
    install_new_atom ("#t")
    kFalse = nextAtom
    install_new_atom ("#f")
    kEq = nextAtom
    install_new_atom ("eq")
    kCar= nextAtom
    install_new_atom ("car")
    kCdr = nextAtom
    install_new_atom ("cdr")
    kAtom = nextAtom
    install_new_atom ("atom")
    kCond = nextAtom
    install_new_atom ("cond")
    kCons = nextAtom
    install_new_atom ("cons")
    kQuote = nextAtom
    install_new_atom ("quote")
    //fmt.printf ("\nnil=%v #t=%v #f=%v eq=%v car=%v cdr=%v atom=%v cond=%v cons=%v quote=%v\n", kNil, kTrue, kFalse, kEq, kCar, kCdr, kAtom, kCond, kCons, kQuote)
}



first :: proc (l : MemPtr) -> MemPtr {
    return Car (l)
}
second :: proc (l : MemPtr) -> MemPtr {
    return Car (Cdr (l))
}
third :: proc (l : MemPtr) -> MemPtr {
    return Car (Cdr (Cdr (l)))
}
rest :: proc (l : MemPtr) -> MemPtr {
    return Cdr (l)
}

panic :: proc (s : string) {
    fmt.printf ("\n\e[31mpanic\e[0m %v\n\n", s)
    os.exit (1)
}
fatal :: proc (s : string) {
    fmt.printf ("\n\e[31mfatal\e[0m %v\n\n", s)
}
