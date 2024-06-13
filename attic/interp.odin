package smalllisp

import "core:fmt"
import "core:strings"
import uni "core:unicode/utf8"

// Eval evaluates the given expression given an environment - a stack of bindings (an Alist) {name:value}
// Eval peels off the low-hanging fruit then punts to Apply() for evaluating anonynmous functions (lambdas).
// Eval places its result on the result stack.
// Eval may use the temp stack, but any temps it created can be discarded.
// Eval may refer to parameters stack but does not mutate it.

Eval :: proc (e : Sexpr, env : Alist) -> MemPtr {
    fmt.printf ("Eval [%v] %v in %v\n", e, format (e), format (env))
    if is_Nil (e) {
	return kNil
    } else if is_Atom (e) { // e is an atom ...
	switch (e) {
	case kNil: 
	    return kNil
	case kTrue: 
	    return kTrue
	case kFalse: 
	    return kFalse
	    case:
	    v := lookup (e, env)
	    return v
	}
    } else { // e is a list
	first_item := Car (e)
	if !is_Atom (first_item) { // (car e) is a list, too
	    // first item is a list, hence, this list must be an anonymous function (a LAMBDA)
	    remainder := Cdr (e)
	    return Apply_anonymous_function (first_item, rest (e), env)
	} else { // (car e) is an atom, it must be one of the builtins
	    fmt.printf ("Eval switching on %v %v cond=%v\n", atom_name (first_item), format (atom_name (first_item)), kCond)
	    switch (atom_name (first_item)) {
	    case kEq: // "eq"
		if Eval (second (e), env) == Eval (third (e), env) {
		    return kTrue
		} else {
		    return kNil
		}
	    case kCar: // "car"
		return first (Eval (second (e), env))
	    case kCdr: // "cdr"
		return second (Eval (second (e), env))
	    case kAtom:  // "atom"
		if is_Atom (Eval (second (e), env)) {
		    return kTrue
		} else {
		    return kNil
		}
	    case kCons: // "cons"
		return (Cons (Eval (second (e), env), Eval (third (e), env)))
	    case kQuote: // "quote"
		return (second (e))
	    case kCond: // "cond"
		return interpret_conditional (rest (e), env)
	    case: // else error
		panic (fmt.aprintf ("Eval %v %v %v %v", e, format (e), env, format (env)))
		return kNil
	    }
	}
    }
    panic (fmt.aprintf ("Eval fell through %v %v", format (e), format (env)))
    return kNil
}

Apply_anonymous_function :: proc (f : Sexpr, args: Sexpr, env : Alist) -> MemPtr {
    // f = (lambda (p1 p2 ...) (body))
    // args = (a1 a2 ...)
    // extend environment by binding each parameter (p) to corresponding arg (a), then Eval the body in that new environment
    // a binding is a simple Cons that creates a dotted pair, e.g. ((p1 . a1) (p2 . a2) ...)
    parameter_list := Car (Cdr (f))
    additional_env := bind_args_to_parameters (args, parameter_list)
    extended_env := lisp_append_destructively (additional_env, env)
    body := Car (Cdr (Cdr (f)))
    return Eval (body, env) //!
}

interpret_conditional ::  proc (args: Sexpr, env : Alist) -> MemPtr {
    // args is a list of pairs (except for the last item, maybe)
    // ... condition (t/nil) : action ...
    // take first action whose condition is t, error if no condition evals to t
    // return true if handled, else false
    if kNil == args {
	fatal ("cond: no condition evaluates to #t")
	return kNil
    } else {
	triggered := false
	v := Eval (first (args), env)
	if v == kTrue {
	    triggered = true
	    if list_length (args) > 1 {
		return Eval (second (args), env)
	    } else {
		return kTrue
	    }
	}
	if triggered {
	    return kTrue
	} else {
	    if kTrue == interpret_conditional (rest (rest (args)), env) {
		return kTrue
	    }
	}
    }
    return kNil
}

lookup :: proc (a : MemPtr, env: MemPtr) -> MemPtr {
    // return the value of "a" within the given environment, or kNil if not found
    // env is a stack of pairs ... { name : value } ...
    if env == kNil {
	return kNil // end of the line - not found
    } else {
	top := first (env)
	name := first (top)
	if a == name {
	    return second (top)
	} else {
	    return lookup (a, (rest (rest (env))))
	}
    }
    return kNil
}

bind_args_to_parameters :: proc (parameter_names : MemPtr, values : MemPtr) -> MemPtr {
    if parameter_names == kNil && values == kNil {
	// end of both lists
	return kNil
    } else if parameter_names == kNil || values == kNil {
	panic (fmt.aprintf ("unbalanced lists in bind_args_to_parameters %v %v", parameter_names, values))
    } else {
	name := Car (parameter_names)
	value := Car (values)
	binding := Cons (name, value)
	return Cons (binding, bind_args_to_parameters (rest (parameter_names), rest (values)))
    }
    return kNil
}

lisp_append_destructively :: proc (l1 : MemPtr, l2 : MemPtr) -> MemPtr {
    snap_together (l1, l2)
    return l1
}

snap_together :: proc  (l1 : MemPtr, l2 : MemPtr) {
    if kNil == Cdr (l1) {
	Set (Cdr (l1), l2)
    } else {
	snap_together (Cdr (l1), l2)
    }
}


list_length :: proc (l : MemPtr) -> int {
    return list_length_rec (l, 0)
}

list_length_rec :: proc (l : MemPtr, i : int) -> int {
    if kNil == l {
	return i
    } else {
	return 1 + list_length_rec (Cdr (l), i)
    }
}

atom_name :: proc (p : MemPtr) -> MemPtr {
    return p
}
