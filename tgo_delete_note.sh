#!/bin/bash

mkdir -p x
cd x

jq .note_id add-note-to-issue.out >note.id
y=$( sed -e 's/"//g' <note.id )
echo note_id=$y
wget -o delete-note.err -O delete-note.out "http://127.0.0.1:12138/api/v1/delete-note?note_id=$y"

if grep success delete-note.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 1

