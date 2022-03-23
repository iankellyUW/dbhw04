  1: #!/home/pschlump/anaconda3/bin/python
  2: #!/use/bin//python3
  3: 
  4: # TODO 
  5: # 1. Read in a config file - for http://localhost:12128
  6: # 2. Do tests - hard coded
  7: # 3. Do Get tests
  8: # 4. Compare JSON data for criteria
  9: # 5. Hard code compare results
 10: # 6. Add command line - for what tests to run.
 11: 
 12: """
 13: See: https://www.geeksforgeeks.org/get-post-requests-using-python/
 14: """
 15: 
 16: 
 17: # importing the requests library 
 18: import requests 
 19: import json 
 20: 
 21: #################################################################################
 22: def get1( URL, PARAMS ):
 23: 
 24:     # sending get request and saving the response as response object 
 25:     r = requests.get(url = URL, params = PARAMS) 
 26: 
 27:     # extracting data in json format 
 28:     data = r.json() 
 29: 
 30:     stat = data['status']
 31: 
 32:     print("Status:%s\n" % (stat)) 
 33: 
 34:     return data
 35: 
 36: 
 37: 
 38: 
 39: 
 40: #################################################################################
 41: def post1( URL, PARAMS ):
 42: 
 43:     # sending post request and saving response as response object 
 44:     r = requests.post(url = URL, data = PARAMS) 
 45: 
 46:     # extracting response text 
 47:     pastebin_url = r.text 
 48:     print("The pastebin URL is:%s" % pastebin_url) 
 49: 
 50: 
 51: 
 52: 
 53: #################################################################################
 54: n_err = 0
 55: 
 56: 
 57: #################################################################################
 58: # @app.route('/status', method=['OPTIONS', 'GET'])
 59: data = get1( "http://localhost:12128/api/v1/status", {} )
 60: 
 61: 
 62: #################################################################################
 63: #@app.route('/api/v1/issue-list', method=['OPTIONS', 'GET'])
 64: data = get1( "http://localhost:12128/api/v1/issue-list", {} )
 65: print ( "issue-list: {}".format(json.dumps(data)) )
 66: 
 67: if data['n_rows'] == len(data['data']):
 68:     print ( "Test length of data passed." )
 69: else:
 70:     n_err = n_err + 1
 71:     print ( "FAIL" )
 72: 
 73: 
 74: #################################################################################
 75: #@app.route('/api/v1/get-issue-detail', method=['OPTIONS', 'GET'])
 76: data = get1( "http://localhost:12128/api/v1/get-issue-detail?issue_id=adcc6ae9-a1db-456a-aa49-427a7111c93e", {} )
 77: print ( "issue-detail: {}".format(json.dumps(data)) )
 78: 
 79: if data['n_rows'] == len(data['data']):
 80:     print ( "Test length of data passed. line:74" )
 81: else:
 82:     n_err = n_err + 1
 83:     print ( "FAIL" )
 84: 
 85: 
 86: if data['n_rows'] == 1:
 87:     print ( "Test length of data incorrect. line:81" )
 88: else:
 89:     n_err = n_err + 1
 90:     print ( "FAIL" )
 91: 
 92: 
 93: if data['data'][0]['n_rows_note'] == len(data['data'][0]['note']):
 94:     print ( "Test length of note passed." )
 95: else:
 96:     n_err = n_err + 1
 97:     print ( "FAIL" )
 98: 
 99: if data['data'][0]['n_rows_note'] == 2:
100:     print ( "Test length of data incorrect." )
101: else:
102:     n_err = n_err + 1
103:     print ( "FAIL" )
104: 
105: 
106: 
107: 
108: #@app.route('/api/v1/hello', method=['OPTIONS', 'GET'])
109: #@app.route('/api/v1/global-data.js', method=['OPTIONS', 'GET'])
110: #@app.route('/api/v1/db-version', method=['OPTIONS', 'GET'])
111: #@app.route('/api/v1/search-keyword', method=['OPTIONS', 'GET'])
112: #@app.route('/api/v1/get-config', method=['OPTIONS', 'GET'])
113: #@app.route('/api/v1/issue-list', method=['OPTIONS', 'GET'])
114: #@app.route('/api/v1/create-issue', method=['OPTIONS', 'GET']) # POST
115: #@app.route('/api/v1/delete-issue', method=['OPTIONS', 'GET']) # POST
116: #@app.route('/api/v1/update-issue', method=['OPTIONS', 'GET']) # POST
117: #@app.route('/api/v1/add-note-to-issue', method=['OPTIONS', 'GET']) # POST
118: #@app.route('/api/v1/delete-note', method=['OPTIONS', 'GET']) # POST
119: #@app.route('/api/v1/update-severity', method=['OPTIONS', 'GET']) # POST
120: #@app.route('/api/v1/update-state', method=['OPTIONS', 'GET']) # POST
121: #@app.route('/api/v1/get-state', method=['OPTIONS', 'GET'])
122: #@app.route('/api/v1/get-severity', method=['OPTIONS', 'GET'])
123: 
124: 
125: 
126: #@app.route('/api/v1/note', method=['OPTIONS', 'DELETE'])
127: #@app.route('/api/v1/note', method=['OPTIONS', 'PUT'])
128: #@app.route('/api/v1/get-note', method=['OPTIONS', 'GET'])
129: #@app.route('/api/v1/issue', method=['OPTIONS', 'GET', 'POST', 'PUT', 'DELETE'])
130: #@app.route('/api/v1/issue', method=['OPTIONS', 'POST'])
131: #@app.route('/api/v1/issue', method=['OPTIONS', 'PUT'])
132: #@app.route('/api/v1/issue', method=['OPTIONS', 'DELETE'])
133: #@app.route('/api/v1/note', method=['OPTIONS', 'GET'])
134: #@app.route('/api/v1/note', method=['OPTIONS', 'PUT'])
135: #@app.route('/api/v1/note', method=['OPTIONS', 'POST'])
136: #@app.route('/api/v1/state', method=['OPTIONS', 'GET'])
137: #@app.route('/api/v1/severity', method=['OPTIONS', 'GET'])
138: 
139: if n_err > 0 :
140:     print ( "FAILED" )
141: else:
142:     print ( "PASS" )
143: 
144: 
