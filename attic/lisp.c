/*-*- mode:c;indent-tabs-mode:nil;c-basic-offset:2;tab-width:8;coding:utf-8 -*-│
│vi: set net ft=c ts=2 sts=2 sw=2 fenc=utf-8                                :vi│
╞══════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2021 Justine Alexandra Roberts Tunney                              │
│                                                                              │
│ Permission to use, copy, modify, and/or distribute this software for         │
│ any purpose with or without fee is hereby granted, provided that the         │
│ above copyright notice and this permission notice appear in all copies.      │
│                                                                              │
│ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL                │
│ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED                │
│ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE             │
│ AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL         │
│ DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        │
│ PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER               │
│ TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR             │
│ PERFORMANCE OF THIS SOFTWARE.                                                │
╚─────────────────────────────────────────────────────────────────────────────*/
#include "libc/errno.h"
#include "libc/runtime/runtime.h"
#include "libc/str/str.h"

#define Null        0200000
#define Set(i, x)   M[(Null + i) & 0xffffffff] = x
#define Get(i)      M[(Null + i) & 0xffffffff]
#define Car(i)      (int)Get(i)
#define Cdr(i)      (int)(Get(i) >> 32)
#define Key(i)      Car(i + 1)
#define Val(i)      Cdr(i + 1)
#define Make(h, t)  ((unsigned)(h) | (unsigned long long)(t) << 32)
#define Alloc(x)    (Set(--cx, x), cx)
#define Puts(fd, s) write(fd, s, strlen(s))
#define Ord(x)      x

char ob[512];
jmp_buf undefined;
unsigned long long M[Null * 2];
int (*funcall)(), ax, cx, dx, tp, op, depth, fail;
int kEq, kCar, kCdr, kCond, kAtom, kCons, kQuote, kDefine, kMacro;
char tape[512] = "NIL T EQ CAR CDR ATOM COND CONS QUOTE MACRO DEFINE ";
short kTpEnc[25] = {0140001, 0140001, 0140001, 0140001, 0160002,
                    0160002, 0160002, 0160002, 0160002, 0170003,
                    0170003, 0170003, 0170003, 0170003, 0174004,
                    0174004, 0174004, 0174004, 0174004, 0176005,
                    0176005, 0176005, 0176005, 0176005, 0176005};

static inline Head(x) {
  if (x < 0) {
    return Car(x);
  } else if (!x) {
    return +0;
  } else {
    Throw2(kCar, x);
  }
}

static inline Tail(x) {
  if (x < 0) {
    return Cdr(x);
  } else if (!x) {
    return -0;
  } else {
    Throw2(kCdr, x);
  }
}

static inline Eval(e, a) {
  return Apply(e, a, 0);
}

static inline Peel(x, a) {
  return a && x == Key(a) ? Cdr(a) : a;
}

Cons(x, y) {
  if (cx > -Null) {
    return Alloc(Make(x, y));
  } else {
    Throw(kCons);
  }
}

Throw2(x, y) {
  Throw(List(x, y));
}

Throw(x) {
  if (fail < 255) ++fail;
  longjmp(undefined, ~x);
}

Alist(x, y, a) {
  return Cons(Cons(x, y), a);
}

List(x, y) {
  return Cons(x, Cons(y, -0));
}

Bsr(x, i) {
  return x ? Bsr(x >> 1, i + 1) : i;
}

Probe(h, p) {
  return (h + p * p) & (Null - 1);
}

Hash(h, x) {
  return ((h + x) * 60611 + 20485) & (Null - 1);
}

Intern(x, y, h, p) {
  if (x == Car(h) && y == Cdr(h)) return h;
  if (Car(h)) return Intern(x, y, Probe(h, p), p + 1);
  Set(h, Make(x, y));
  return h;
}

ReadAtom() {
  int x, y;
  ax = y = 0;
  do x = ReadChar();
  while (x <= Ord(' '));
  if (x > Ord(')') && dx > Ord(')')) y = ReadAtom();
  return Intern(x, y, (ax = Hash(x, ax)), 1);
}

ReadList() {
  int x;
  if ((x = Read()) > 0) {
    if (Car(x) == Ord(')')) return -0;
    if (Car(x) == Ord('.') && !Cdr(x)) {
      x = Read();
      ReadList();
      return x;
    }
  }
  return Cons(x, ReadList());
}

ReadChar() {
  int b, a = dx;
  dx = ReadByte();
  if (a >= 0300) {
    for (b = 0200; a & b; b >>= 1) {
      a ^= b;
    }
    while ((dx & 0300) == 0200) {
      a <<= 6;
      a |= dx & 0177;
      dx = ReadByte();
    }
  }
  return towupper(a);
}

ReadByte() {
  int n;
  if (!tape[tp]) {
    n = read(0, tape, sizeof(tape) - 1);
    if (n <= 0) exit(fail);
    tape[n] = 0;
    tp = 0;
  }
  return tape[tp++] & 255;
}

Flush() {
  int n, i = 0;
  while (i < op) {
    if ((n = write(1, ob + i, op - i)) > 0) {
      i += n;
    } else if (errno != EINTR) {
      exit(errno);
    }
  }
  op = 0;
}

PrintChar(c) {
  int e, i, n;
  if (op + 6 > sizeof(ob)) Flush();
  if (c < 0200) {
    ob[op++] = c;
    if (c == Ord('\n')) Flush();
  } else {
    e = kTpEnc[Bsr(c, -1) - 7];
    i = n = e & 255;
    do ob[op + i--] = 0200 | (c & 077);
    while (c >>= 6, i);
    ob[op] = c | e >> 8;
    op += n + 1;
  }
}

PrintAtom(x) {
  do PrintChar(Car(x));
  while ((x = Cdr(x)));
}

PrintList(x) {
  PrintChar(Ord('('));
  if (x < 0) {
    Print(Car(x));
    while ((x = Cdr(x))) {
      if (x < 0) {
        PrintChar(Ord(' '));
        Print(Car(x));
      } else {
        PrintDot();
        Print(x);
        break;
      }
    }
  }
  PrintChar(Ord(')'));
}

Print(x) {
  if (1. / x < 0) {
    PrintList(x);
  } else {
    PrintAtom(x);
  }
}

PrintDot() {
  PrintChar(Ord(' '));
  PrintChar(Ord('.'));
  PrintChar(Ord(' '));
}

Newline() {
  PrintChar(Ord('\r'));
  PrintChar(Ord('\n'));
}

Read() {
  int t = ReadAtom();
  if (Car(t) != Ord('(')) return t;
  return ReadList();
}

Gc(A, x) {
  int C, B = cx;
  x = Copy(x, A, A - B), C = cx;
  while (C < B) Set(--A, Get(--B));
  return cx = A, x;
}

Copy(x, m, k) {
  int l, r;
  if (x < m) {
    l = Car(x);
    r = Cdr(x);
    r = Copy(r, m, k);
    l = Copy(l, m, k);
    return Cons(l, r) + k;
  } else {
    return x;
  }
}

Evlis(x, a) {
  if (x) {
    return Cons(Eval(Head(x), a), Evlis(Tail(x), a));
  } else {
    return x;
  }
}

Pairlis(x, y, a) {
  if (x < 0) {
    return Alist(Car(x), Head(y), Pairlis(Cdr(x), Tail(y), Peel(Car(x), a)));
  } else if (!x) {
    return a;
  } else {
    return Alist(x, y, Peel(x, a));
  }
}

Bind(x, y, a, u) {
  if (x < 0) {
    return Alist(Car(x), Eval(Head(y), u),
                 Bind(Cdr(x), Tail(y), Peel(Car(x), a), u));
  } else if (!x) {
    return a;
  } else {
    return Alist(x, Evlis(y, u), Peel(x, a));
  }
}

Assoc(x, y) {
  int k, v, t;
  for (; y < 0; y = t) {
    t = Cdr(y);
    k = Key(y);
    v = Val(y);
    if (x == k) {
      return v;
    }
  }
  Throw(x);
}

Evcon(c, a, t) {
  int x, d, y, e;
  for (; c; c = d) {
    if (c < 0) {
      x = Car(c);
      d = Cdr(c);
      if (x < 0) {
        y = Car(x);
        e = Cdr(x);
        if (Eval(y, a)) {
          return Apply(Head(e), a, t);
        }
      } else {
        Throw2(kCond, c);
      }
    } else {
      Throw2(kCond, c);
    }
  }
  return c;
}

Apply(e, a, t) {
  int f, x, l, p, b, u, A;
  if (!e) return e;
  if (e > 0) return t ? e : Assoc(e, a);
  x = Cdr(e);
  f = Car(e);
  if (f == kCond) return Evcon(x, a, t);
  if (t) return e;
  if (f > 0) {
    u = Head(x);
    t = Tail(x);
    if (f == kQuote) return u;
    if (f == kCons) return Cons(Eval(u, a), Eval(Head(t), a));
    if (f == kEq) return Eval(u, a) == Eval(Head(t), a);
    if (f == kAtom) return Eval(u, a) >= 0;
    if (f == kCar) return Head(Eval(u, a));
    if (f == kCdr) return Tail(Eval(u, a));
    l = Assoc(f, a);
  } else {
    l = f;
  }
  u = a;
  A = cx;
  p = Head(Tail(l));
  b = Head(Tail(Tail(l)));
  if (Head(l) == kMacro) {
    x = funcall(b, Pairlis(p, x, a), 0, a, f, p);
  } else {
    for (;;) {
      u = Bind(p, x, a, u);
      x = funcall(b, u, f, a, f, p);
      if (x < 0 && Car(x) == f) {
        x = Gc(A, Cons(u, Cdr(x)));
        u = Car(x);
        x = Cdr(x);
      } else {
        break;
      }
    }
  }
  return Gc(A, x ? funcall(x, u, 0, a, f, p) : x);
}

Trace(b, u, t, a, f, p) {
  int i, y;
  if (f > 0) {
    Indent(depth);
    PrintChar(Ord('('));
    Print(f);
    for (i = u; p < 0; i = Cdr(i), p = Cdr(p)) {
      PrintChar(Ord(' '));
      Print(Car(p));
      PrintChar(Ord('='));
      Print(Cdr(Car(i)));
    }
    if (p > 0) {
      PrintDot();
      Print(p);
      PrintChar(Ord('='));
      Print(Car(i));
    }
    PrintChar(Ord(')'));
    Newline();
    depth += 2;
  }
  y = Apply(b, u, t);
  if (f > 0) {
    depth -= 2;
    Indent(depth);
    Print(f);
    PrintChar(Ord(' '));
    PrintChar(0x2192);
    PrintChar(Ord(' '));
    Print(y);
    Newline();
  }
  return y;
}

Indent(i) {
  if (i) {
    PrintChar(Ord(' '));
    Indent(i - 1);
  }
}

Setup() {
  ReadAtom();
  ReadAtom();
  kEq = ReadAtom();
  kCar = ReadAtom();
  kCdr = ReadAtom();
  kAtom = ReadAtom();
  kCond = ReadAtom();
  kCons = ReadAtom();
  kQuote = ReadAtom();
  kMacro = ReadAtom();
  kDefine = ReadAtom();
}

Remove(x, y) {
  if (!y) return y;
  if (x == Key(y)) return Cdr(y);
  return Cons(Car(y), Remove(x, Cdr(y)));
}

Define(x, a) {
  return Cons(x, Remove(Car(x), a));
}

main(int argc, char *argv[]) {
  int x, a, A;
  funcall = Apply;
  for (x = 1; x < argc; ++x) {
    if (argv[x][0] == Ord('-') && argv[x][1] == Ord('t')) {
      funcall = Trace;
    } else {
      Puts(2, "Usage: lisp.com [-t] <input.lisp >output.lisp\n");
      exit(1);
    }
  }
  Setup();
  for (a = 0;;) {
    A = cx;
    if (!(x = setjmp(undefined))) {
      x = Read();
      if (x < 0 && Car(x) == kDefine) {
        a = Gc(0, Define(Tail(x), a));
        continue;
      }
      x = Eval(x, a);
    } else {
      x = ~x;
      PrintChar(Ord('?'));
    }
    Print(x);
    Newline();
    Gc(A, 0);
  }
}
