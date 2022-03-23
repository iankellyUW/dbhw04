#!/bin/bash

mkdir -p x
cd x

#// http.Handle("/api/v1/delete-issue"
wget -o delete-issue.err -O delete-issue.out 'http://127.0.0.1:12138/api/v1/delete-issue?issue_id=7ead6793-9100-4683-9437-78c692053c3a'

if grep success delete-issue.out >/dev/null ; then
	echo PASS
	exit 0
fi

echo FAILED
exit 1

