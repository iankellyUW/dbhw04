#!/bin/bash

mkdir -p x
cd x

#// http.Handle("/api/v1/create-issue", http.HandlerFunc(ResponceHandlerApiV1CreateIssue))
wget -o create-issue.err -O create-issue.out 'http://127.0.0.1:12138/api/v1/create-issue?body=bod&title=title'

# {"status":"success","id":"518e4c41-b4e2-42a9-a8bf-61ccd9446db0"}
jq .status create-issue.out | grep "success" 
if jq .status create-issue.out | grep "success" >/dev/null 2>&1 ; then
	echo PASS
else
	x=$( jq .status create-issue.out )
	echo "Status is not 'success' - failed status == ->$x<-"
fi 

jq .id create-issue.out | sed -e 's/"//g' >create-issue.id


