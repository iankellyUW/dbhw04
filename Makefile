
PP=`pwd`
FN=Assignment-04
DIR=../../
IMG=
PY= \
	a04-goserver.go \
	a04-server.py \
	config.py \
	delete-issue-note.sql \
	sample-issues.sql \
	app_config.ini \
	database.ini

all: setup all2
	
run_go_server:
	rm -f 04
	go build
	mkdir -p ./log
	./04 

run_python_server:
	python a04-server.py &

setup:
	go build
	../mk_all_nu.sh

all2: ${FN}.html ${PY}


#%.html: %.raw.md
#	../mk_html.sh $< $@ 

#%.pdf: %.md
#	~/bin/md-to-pdf.sh $<

.PRECIOUS: %.md 
%.md: %.raw.md $(PY) $(IMG)
	m4 -P $< >$@

%.html: %.md
	blackfriday-tool ./$< $@
	echo cat ./${DIR}/css/md.css $@ >/tmp/$@
	cat ./${DIR}/css/pre ./${DIR}/css/markdown.css ./${DIR}/css/post ./${DIR}/css/md.css ./${DIR}/css/hpre $@ ./${DIR}/css/hpost >/tmp/$@
	mv /tmp/$@ ./$@
	echo "file://${PP}/$@" >>open.1

