#	'ensure that formatted text option in draw.io is disabled everywhere'

LANG=nanolisp

all:
	./0D/das2json/das2json ${LANG}.drawio
	./0D/das2json/das2json 0D/python/std/transpile.drawio
	cat py0d.py main.py >_.py
	python3 _.py . 0D/python ${LANG} main ${LANG}.drawio.json transpile.drawio.json

#########

# to install required libs, do this once
install-js-requires:
	npm install ohm-js yargs prompt-sync

clean:
	rm -rf *.json
	rm -f _.py
