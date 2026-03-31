export MAKE_DIR = $(CURDIR)

all:
	make clean
	make once
	make once
	make once

once:
	find . -name compiled -type d -exec rm -fr {} \; || true
	make pollenboots
	raco pollen render index.ptree

pollenboots:
	git clone https://github.com/ds26gte/pollenboots

clean:
	find . -name compiled -type d -exec rm -fr {} \; || true
	find [^p]* -name \*.html -delete || true
	find pl* -name \*.html -delete || true
	make cleanglob

cleanglob:
	rm -f globals.rkt _glossary.rkt
