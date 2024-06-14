// remove special chars like "❲" and "❳"
// replace developer indents with actual indents
// replace developer newlines with actual newlines
function scrubber (s) {
    console.error (s);
    return decodeURI (s.replace (/❲/g, '').replace (/❳/g, ''))

	// .replace (/☞/g,'⤷')
	// .replace (/☜/g,'⤶')
    
	// .replace (/⇩/g,'\n')

	.replace (/☞/g,' ')
	.replace (/☜/g,'')
    
	.replace (/⇩/g,' ')

	.replace (/“/g,'"')
	.replace (/”/g,'"')

	.replace (/-/g,'_')
	.replace (/foreign\?/g,'foreign_Q')
	.replace (/e\*/g,'e_A')
	.replace (/#t/g,'True')
	.replace (/#f/g,'False')

	.replace (/⎰/g,'')
	.replace (/⎱/g,' ')
	.replace (/,]/g,']')
	.replace (/, \)/g,')')
	.replace (/var\?/g, '_isvar')
	.replace (/string\?/g, '_isstring');
}

let fs = require('fs');
let inp = fs.readFileSync(0, 'utf-8');
let outp = scrubber (inp);
console.log (outp);
