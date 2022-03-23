#!/home/pschlump/anaconda3/bin/python
#!/use/bin//python3

# TODO 
# 1. Read in a config file - for http://localhost:12128
# 2. Do tests - hard coded
# 3. Do Get tests
# 4. Compare JSON data for criteria
# 5. Hard code compare results
# 6. Add command line - for what tests to run.

"""
See: https://www.geeksforgeeks.org/get-post-requests-using-python/
"""


# importing the requests library 
import requests 
import json 

#################################################################################
def get1( URL, PARAMS ):

    # sending get request and saving the response as response object 
    r = requests.get(url = URL, params = PARAMS) 

    # extracting data in json format 
    data = r.json() 

    stat = data['status']

    print("Status:%s\n" % (stat)) 

    return data





#################################################################################
def post1( URL, PARAMS ):

    # sending post request and saving response as response object 
    r = requests.post(url = URL, data = PARAMS) 

    # extracting response text 
    pastebin_url = r.text 
    print("The pastebin URL is:%s" % pastebin_url) 




#################################################################################
n_err = 0


#################################################################################
# @app.route('/status', method=['OPTIONS', 'GET'])
data = get1( "http://0.0.0.0:12138/api/v1/status", {} )


#################################################################################
#@app.route('/api/v1/issue-list', method=['OPTIONS', 'GET'])
data = get1( "http://0.0.0.0:12138/api/v1/issue-list", {} )
print ( "issue-list: {}".format(json.dumps(data)) )

if data['n_rows'] == len(data['data']):
    print ( "Test length of data passed." )
else:
    n_err = n_err + 1
    print ( "FAIL" )


#################################################################################
#@app.route('/api/v1/get-issue-detail', method=['OPTIONS', 'GET'])
data = get1( "http://0.0.0.0:12138/api/v1/get-issue-detail?issue_id=adcc6ae9-a1db-456a-aa49-427a7111c93e", {} )
print ( "issue-detail: {}".format(json.dumps(data)) )

if data['n_rows'] == len(data['data']):
    print ( "Test length of data passed. line:74" )
else:
    n_err = n_err + 1
    print ( "FAIL" )


if data['n_rows'] == 1:
    print ( "Test length of data incorrect. line:81" )
else:
    n_err = n_err + 1
    print ( "FAIL" )


if data['data'][0]['n_rows_note'] == len(data['data'][0]['note']):
    print ( "Test length of note passed." )
else:
    n_err = n_err + 1
    print ( "FAIL" )

if data['data'][0]['n_rows_note'] == 2:
    print ( "Test length of data incorrect." )
else:
    n_err = n_err + 1
    print ( "FAIL" )




#@app.route('/api/v1/hello', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/global-data.js', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/db-version', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/search-keyword', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/get-config', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/issue-list', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/create-issue', method=['OPTIONS', 'GET']) # POST
#@app.route('/api/v1/delete-issue', method=['OPTIONS', 'GET']) # POST
#@app.route('/api/v1/update-issue', method=['OPTIONS', 'GET']) # POST
#@app.route('/api/v1/add-note-to-issue', method=['OPTIONS', 'GET']) # POST
#@app.route('/api/v1/delete-note', method=['OPTIONS', 'GET']) # POST
#@app.route('/api/v1/update-severity', method=['OPTIONS', 'GET']) # POST
#@app.route('/api/v1/update-state', method=['OPTIONS', 'GET']) # POST
#@app.route('/api/v1/get-state', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/get-severity', method=['OPTIONS', 'GET'])



#@app.route('/api/v1/note', method=['OPTIONS', 'DELETE'])
#@app.route('/api/v1/note', method=['OPTIONS', 'PUT'])
#@app.route('/api/v1/get-note', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/issue', method=['OPTIONS', 'GET', 'POST', 'PUT', 'DELETE'])
#@app.route('/api/v1/issue', method=['OPTIONS', 'POST'])
#@app.route('/api/v1/issue', method=['OPTIONS', 'PUT'])
#@app.route('/api/v1/issue', method=['OPTIONS', 'DELETE'])
#@app.route('/api/v1/note', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/note', method=['OPTIONS', 'PUT'])
#@app.route('/api/v1/note', method=['OPTIONS', 'POST'])
#@app.route('/api/v1/state', method=['OPTIONS', 'GET'])
#@app.route('/api/v1/severity', method=['OPTIONS', 'GET'])

if n_err > 0 :
    print ( "FAILED" )
else:
    print ( "PASS" )


