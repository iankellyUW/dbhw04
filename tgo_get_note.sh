#!/bin/bash

mkdir -p x
cd x

wget -o create-issue.err -O create-issue.out 'http://127.0.0.1:12138/api/v1/create-issue?body=bod&title=title'
jq .id create-issue.out >issue.id
x=$( sed -e 's/"//g' <issue.id )
echo issue_id=$x
wget -o add-note-to-issue.err -O add-note-to-issue.out "http://127.0.0.1:12138/api/v1/add-note-to-issue?title=Note1&issue_id=$x&body=NoteBody1"
jq .note_id add-note-to-issue.out >note.id
y=$( sed -e 's/"//g' <note.id )
echo note_id=$y
wget -o get-note.err -O get-note.out "http://127.0.0.1:12138/api/v1/get-note?note_id=$y"

if grep success get-note.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 1

