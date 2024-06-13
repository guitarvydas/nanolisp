package smalllisp

// testing

import "core:fmt"


dump_mem :: proc () {
    fmt.printf ("atoms: ")
    for i : Ptr = 0 ; i < nextAtom ; i += 2 {
	fmt.printf (" %X: [%x|%4X]", i, Get (i), Get (i+1))
    }
    fmt.printf ("\nlists: ")
    for i : Ptr = -1 ; i > nextList ; i -= 2 {
	fmt.printf (" %X: [%x|%4X]", i-1, Get (i-1), Get (i))
    }
    fmt.printf ("\nnextAtom=%v nextList=%v\n", nextAtom, nextList)
}

test :: proc (inp : string) {
    initialize ()
    fmt.printf ("\n\n\n*** %v\n", inp)
    open_on_string (inp)
    r := Read ()
    fmt.printf ("test -> %x\n", r)
    dump_mem ()
    close ()
}

test_2 :: proc (inp : string) {
    initialize ()
    fmt.printf ("\n\n\n*** test_2 *** %v\n", inp)
    open_on_string (inp)
    fmt.printf ("test_2 -> %x\n", Read())
    dump_mem ()
    fmt.printf ("test_2 -> %x\n", Read())
    dump_mem ()
    close ()
}

test_read :: proc (inp : string) -> MemPtr {
    initialize ()
    open_on_string (inp)
    r := Read ()
    close ()
    return r
}


main :: proc () {
    initialize ()

    input1 := "1"
    input2 := "12"
    input3 := "123"
    input4 := "1234"
    input5 := "5 6"
    
    input6 := "(A)"
    input7 := "(A B)"
    input8 := "(C (D))"
    input9 := "(E (F G) H)"
    input10 := "(J K . L)"
    
    /* test (input1) */
    /* test (input2) */
    /* test (input3) */
    /* test (input4) */
    /* test_2 (input5) */
    /* test (input6) */
    /* test (input7) */
    /* test (input8) */
    /* test (input9) */
    /* fmt.println (ufFormat (0)) */
    /* fmt.println (ufFormat (6)) */
    /* fmt.println (ufFormat (8)) */
    /* fmt.println (ufFormat (12)) */
    /* fmt.println (ufFormat (18)) */
    /* fmt.println (ufFormat (24)) */
    /* fmt.println (ufFormat (32)) */
    /* fmt.println (ufFormat (40)) */
    /* fmt.println (ufFormat (48)) */

    /* fmt.println (ufFormat (58)) */
    /* fmt.println (ufFormat (60)) */
    /* fmt.println (ufFormat (62)) */
    /* fmt.println (ufFormat (64)) */

    /* fmt.println (ufFormat (-10)) */

    /* fmt.println (format (-10)) */

    /* test (input10) */
    /* fmt.println (mem[0:MemMiddle]) */
    /* 		 fmt.println (mem[MemMiddle:]) */
    /* fmt.println (ufFormat (58)) */
    /* fmt.println (format (-4)) */

    input11 := "A"
    input12 := "(quote A)"
    input13 := "(quote (B))"
    input14 := "(car (quote (C)))"
    input15 := "(quote (D E))"
    input16 := "(car (quote (D E)))"
    input17 := "(quote (F G))"

    /* s := input16 */
    /* fmt.printf ("begin '%v'\n", s) */
    /* r := test_read (s) */
    /* fmt.printf ("r: %v\n", r) */
    /* fmt.printf ("read: %v\n", format (r)) */
    /* print (Eval (r, kNil)) */

    /* s := input16 */
    /* r := test_read (s) */
    /* print (Eval (r, kNil)) */

//    s := "(car (quote (D E)))"
//    s := "(atom (quote X))"
//    s := "(atom (quote (Y Z)))"
//    s := "(eq (quote P) (quote P))"
//    s := "(eq (quote P) (quote Q))"
//    s := "(cons (quote P) (quote Q))"
    s := "(cond () (quote No) (quote Yes) (quote Yes))"
    r := test_read (s)
    print (Eval (r, kNil))

}
