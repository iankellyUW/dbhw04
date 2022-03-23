#!/bin/bash

mkdir -p x
cd x

wget -o create-issue.err -O create-issue.out 'http://127.0.0.1:12138/api/v1/create-issue?body=bodOrig&title=titleOrig'
jq .id create-issue.out >issue.id
x=$( sed -e 's/"//g' <issue.id )
echo issue_id=$x

# http.Handle("/api/v1/update-severity", http.HandlerFunc(HandleApiV1UpdateIssue))
wget -o update-state.err -O update-state.out "http://127.0.0.1:12138/api/v1/update-state?state_id=4&issue_id=$x"

if grep success update-state.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 1

