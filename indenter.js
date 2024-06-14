 // pseudo Python to Python re-formatter
function indenter (str) {
    indentation = [];
    let result = '';
    if (str) {
	str.split ('\n').forEach (line => {
	    let s = indent1 (line.trim ());
	    result += '\n' + s;
	});
    }
    return result;
}

 let indentation = [];
 // we emit code using bracketed notation (- and -) which is compatible
 // lisp pretty-printing, which allows easier debugging of the transpiled code
 // then, for Python, we convert the bracketing into indentation...
 function indent1 (s) {
   let opens = (s.match (/\(-/g) || []).length;
   let closes = (s.match (/-\)/g) || []).length;
     // let r0 = s.trim ();
     let r0 = s;
   let r1 = r0.replace (/\(-/g, '');
   let r2 = r1.replace (/-\)/g, '');
   let spaces = indentation.join ('');
   let r  = spaces + r2.replace (/\n/g, spaces);
   let diff = opens - closes;
   if (diff > 0) {
       while (diff > 0) {
           indentation.push ('  ');
           diff -=1;
       }
   } else {
     while (diff < 0) {
         indentation.pop ();
         diff += 1;
     }
   }
   return r;
 }

let fs = require('fs');
let inp = fs.readFileSync(0, 'utf-8');
let outp = indenter (inp);
console.log (outp);
