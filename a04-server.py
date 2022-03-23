#!/usr/bin/python3

import bottle
# from bottle import get, route, static_file, run, error, response, request, abort, put, delete, post, app
from bottle import error, response, request, abort, static_file
import psycopg2
import datetime
import os
from config import config
from urllib.parse import parse_qs
import json
import uuid
        
cwd = ""
root_dir = './www'
app = bottle.app()


#################################################################################################################################
#################################################################################################################################
class EnableCors(object):
    name = 'enable_cors'
    api = 2

    def apply(self, fn, context):
        def _enable_cors(*args, **kwargs):
            # set CORS headers
            response.headers['Access-Control-Allow-Origin'] = '*'
            response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
            response.headers['Access-Control-Allow-Headers'] = 'Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token'

            if bottle.request.method != 'OPTIONS':
                # actual request; reply with the actual response
                return fn(*args, **kwargs)

        return _enable_cors


#################################################################################################################################
# General Suppot Functions
#################################################################################################################################
def gen_uuid():
    u = "{}".format(uuid.uuid4())
    return u

def required_param( param, req ):
    # print ( "param={} req={}".format ( param, req ) )
    for item in req:
        # print ( "item={}".format(item) )
        if not ( item in param ) :
            # print ( "Error occuring, missing {} parameter".format(item))
            abort(406, "Missing {} from parameters".format(item))
            return False
    return True

#################################################################################################################################
# Database Interface
#################################################################################################################################

db_conn = None
db_connection_info = None
db_version_str = ""

def connect():
    """ Connect to the PostgreSQL database server """
    global db_conn
    global db_connection_info
    db_conn = None
    param = None
    try:
        db_connection_info = config() # read database connection parameters
        # print ( "db_connetion_info = {}".format(db_connection_info ) )

        # connect to the PostgreSQL server
        print('Connecting to the PostgreSQL database...')
        db_conn = psycopg2.connect(**db_connection_info)
		
        cur = db_conn.cursor()              
        cur.execute('SELECT 123 as "x"')
        t = cur.fetchone()
        # print ( "t={}".format(t) )
        cur.close()
       
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)

def disconnect():
    global db_conn
    if db_conn is not None:
        db_conn.close() # close the communication with the PostgreSQL
        db_conn = None

def default(o):
    if isinstance(o, (datetime.date, datetime.datetime)):
        return o.isoformat()

def create_dict(obj, fields):
    mappings = dict(zip(fields, obj))
    return mappings

def run_select ( stmt, data ):
    global db_conn
    cur = None
    try:
        cur = db_conn.cursor()                      # create a cursor
        cur.execute(stmt, data)
        colnames = [desc[0] for desc in cur.description]
        #d# print ( "colnames={}".format ( colnames ) )
        rows = cur.fetchall()
        n_rows = cur.rowcount
        result = []
        for row in rows:
            result.append(create_dict(row, colnames)) 
        cur.close()

        ss = json.dumps(
          result,
          sort_keys=True,
          indent=1,
          default=default
        )

        return "{"+"\"status\":\"success\",\"n_rows\":{},\"data\":{}".format(n_rows,ss)+"}"

    except (Exception, psycopg2.DatabaseError) as error:
        print ( "Database Error {}".format(error) )
        return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
    finally:
        if cur is not None:
            cur.close()
    
def run_select_raw ( stmt, data ):
    global db_conn
    cur = None
    try:
        cur = db_conn.cursor()                      # create a cursor
        cur.execute(stmt, data)
        colnames = [desc[0] for desc in cur.description]
        #d# print ( "colnames={}".format ( colnames ) )
        rows = cur.fetchall()
        n_rows = cur.rowcount
        result = []
        for row in rows:
            result.append(create_dict(row, colnames)) 
        cur.close()

        ss = json.dumps(
          result,
          sort_keys=True,
          indent=1,
          default=default
        )

        datarv = {
            "status": "success",
            "result": result,
            "n_rows": n_rows,
            "column_names": colnames,
            "rows": rows,
            "json_str": ss
        }

        # print ( "return data is {}".format(datarv) )

        db_conn.commit()
        return datarv

    except (Exception, psycopg2.DatabaseError) as error:
        print ( "Database Error {}".format(error) )
        datarv = {
            "status": "error",
            "msg": "{}".format(error)
        }
        db_conn.commit()
        return datarv
    finally:
        if cur is not None:
            cur.close()
   
 
def run_insert ( stmt, data ) :
    global db_conn
    cur = None
    try:
        cur = db_conn.cursor()                      # create a cursor
        cur.execute(stmt, data)
        cur.close()
        return "{"+"\"status\":\"success\",\"id\":\"{}\"".format(data["id"])+"}"

    except (Exception, psycopg2.DatabaseError) as error:
        return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
    finally:
        if cur is not None:
            cur.close()
    
def run_update ( stmt, data ) :
    global db_conn
    cur = None
    try:
        cur = db_conn.cursor()                      # create a cursor
        cur.execute(stmt, data)
        rowcount = cur.rowcount
        cur.close()

        return "{"+"\"status\":\"success\",\"n_rows\":{}".format(rowcount)+"}"

    except (Exception, psycopg2.DatabaseError) as error:
        return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
    finally:
        if cur is not None:
            cur.close()
    
def run_delete ( stmt, data ) :
    global db_conn
    cur = None
    try:
        cur = db_conn.cursor()                      # create a cursor
        cur.execute(stmt, data)
        rowcount = cur.rowcount
        cur.close()
        return "{"+"\"status\":\"success\",\"n_rows\":{}".format(rowcount)+"}"

    except (Exception, psycopg2.DatabaseError) as error:
        return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
    finally:
        if cur is not None:
            cur.close()

    



#################################################################################################################################
# Routes 
#################################################################################################################################

# @get('/api/v1/hello')
@app.route('/api/v1/hello', method=['OPTIONS', 'GET'])
def hello():
    response.content_type = "application/json"
    return "{\"msg\":\"hello world\"}"

# @get('/api/v1/global-data.js')
@app.route('/api/v1/global-data.js', method=['OPTIONS', 'GET'])
def global_data():
    response.content_type = "text/javascript;charset=UTF-8"
    s1 = run_select ( "SELECT * FROM i_state", {})
    s2 = run_select ( "SELECT * FROM i_severity", {})
    return "var g_state = {s1};\n\nvar g_severity = {s2};\n\n".format( s1 = s1, s2 = s2 );
    





# @get('/api/v1/status')
@app.route('/api/v1/status', method=['OPTIONS', 'GET'])
def status():
    response.content_type = "application/json"
    cur = None
    dict = {}
    if request.method == 'GET':
        dict = parse_qs(request.query_string)
    try:
        cur = db_conn.cursor()              
        cur.execute('SELECT \'Database-OK\' as "x"')
        t = cur.fetchone()
        # print ( "server status t={}".format(t) )
        cur.close()
        db_conn.commit()
        # return "{"+"\"status\":\"success\",\"server_status\":\"Server-OK\",\"database_status\":\"{}\"".format(t[0])+"}"
        ss = json.dumps(
          dict,
          sort_keys=True,
          indent=1,
          default=default
        )
        return "{"+"\"status\":\"success\",\"server_status\":\"Server-OK\",\"database_status\":\"{}\",\"params\":{}".format(t[0],ss)+"}"
    except (Exception, psycopg2.DatabaseError) as error:
        return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
    finally:
        if cur is not None:
            cur.close()

# @get('/status')
@app.route('/status', method=['OPTIONS', 'GET'])
def status_2():
    return status()

# @get('/api/v1/db-version')
@app.route('/api/v1/db-version', method=['OPTIONS', 'GET'])
def db_version():
    response.content_type = "application/json"
    global db_version_str
    if db_version_str == "" or db_version_str == None:
        db_version_str = run_select ( 'SELECT version()', {} )
    db_conn.commit()
    return db_version_str

# @get('/api/v1/search-keyword')
@app.route('/api/v1/search-keyword', method=['OPTIONS', 'GET'])
def search_keyword():
    response.content_type = "application/json"
    dict = parse_qs(request.query_string)
    if not required_param(dict,["kw"]):
        return
    kw = dict["kw"]
    # print ( "kw={}".format( kw ) )
    lang = 'english'
    try:
        cur = db_conn.cursor()              
        cur.execute('SELECT value FROM i_config where name = \'language\'')
        t = cur.fetchone()
        # print ( "server status t={} t[0]=->{}<-".format(t, t[0]) )
        lang = t[0]
        cur.close()
        db_conn.commit()
    except (Exception, psycopg2.DatabaseError) as error:
        lang = 'english'
    finally:
        if cur is not None:
            cur.close()
    # return run_select ( "SELECT * FROM i_issue_st_sv where words @@ to_tsquery('english'::regconfig,%(kw)s)", { "kw":kw[0] } )
    return run_select ( "SELECT * FROM i_issue_st_sv where words @@ to_tsquery('{}'::regconfig,%(kw)s)".format(lang), { "kw":kw[0] } )


# @get('/api/v1/get-config')
@app.route('/api/v1/get-config', method=['OPTIONS', 'GET'])
def get_config():
    response.content_type = "application/json"
    return run_select ( "SELECT * FROM i_config", {})

#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
#   use `run_select ( "SELECT * FROM i_issue_st_sv", {})`    
#  to select back the set of issues  in the database         
#  that are not `Deleted`.   Create the view i_issue_st_sv   
#  to join from i_issue to i_state and i_severity so that    
#  both the state_id and the state are returned (this is the i_issue_st_sv view).  Sort the   
#  data into descending severity_id, and descending creation 
#  and update  dates.   The view i_issue_st_sv should be     
#  added to your data model that you turn in.                
#--------------------------------------------------------------------------------------------------------
# /api/issue-list
# @get('/api/v1/issue-list')
@app.route('/api/v1/issue-list', method=['OPTIONS', 'GET'])
def issue_list():
    return run_select ( "SELECT * FROM i_issue_st_sv", {})


#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
#  perfom an insert into i_issue with parameters from the GET or POST.             
# The paramters should require 'body' and 'title' but allow for                  
# defaults for "severity_id" and "issue_id" .  These should default              
# to '1' for the first ID in the set of ids.                                     
# For "issue_id" it should default to a new UUID if not specified.              
# Use `run_insert` do to the insert and remember to commit the                   
# change to the database.  The return from `run_insert` will                    
# have the status/success and ID to return to the client                       
# application.                                                                
#--------------------------------------------------------------------------------------------------------
# /api/create-issue
# @get('/api/v1/create-issue')
@app.route('/api/v1/create-issue', method=['POST', 'GET', 'OPTIONS'])
def create_issue():
    return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"


#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
# Use a passed 'issue_id' to do a delete from it i_issue table.                  
#--------------------------------------------------------------------------------------------------------
# /api/delete-issue
# @get('/api/v1/delete-issue')
@app.route('/api/v1/delete-issue', method=['OPTIONS', 'GET', 'POST'])
def delete_issue():
    return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"

#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
#  Take as input the issue_id, the title, the body and optionally a new severity_id and a new state_id
# and update the i_issue rowo specified by the issue_id.
#--------------------------------------------------------------------------------------------------------
# /api/update-issue
# @get('/api/v1/update-issue')
@app.route('/api/v1/update-issue', method=['OPTIONS', 'GET', 'POST'])
def update_issue():
    return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"


#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
#  Return a set of data from i_issue (or i_issue_st_sv would be more accurate) with all of the assocated
# notes for the issue.  This is the data that is used to paint the issue detail page.
#
# If you have an issue with:
#		title == "Ho - The Server is Broken"
#		body == "Yes this is true... The sever is down - not working. Getting error 52114"
#		severity_id,severity == 7, 'Severe - System down'
#		state_id,state == 2, 'Verified'
# And it has 2 notes:
#      1)
#		  i_note.title == "I verified that it is true."
#		  i_note.body == "Yes the server is down"
#      2)
#		  i_note.title == "Restart Failed"
#		  i_note.body == "Tried to just restart server - it failed."
#
# Then The JSON data returned would be (Note the order of the fields will be different):
#
# {
#   "status": "success"
#   "data": [
#		{
#          "id":  "<< Some UUID >>",
#          "title": "Ho - The Server is Broken",
#          "body": "Yes this is true... The sever is down - not working. Getting error 52114",
#          "state": "Verified",
#          "state_id": 2,
#          "severity": "Severe - System down"
#          "severity_id": 7,
#          "updated": "<< Some Timestamp data, might be null >>",
#          "created": "<< A created timestamp >>",
#			"n_rows_note": 2,
#	        "note": [
#				{
#					"id": "<< A Different UUID >>",
#					"issue_id": "<< Some UUID (same as the i_issue UUID) >>",
#					"seq": <<A Sequence Number, 55, 88 etc>>,
#					"title": "I verified that it is true.",
#					"body": "Yes the server is down"
#				},
#				{
#					"id": "<< A 2nd Different UUID >>",
#					"issue_id": "<< Some UUID (same as the i_issue UUID) >>",
#					"seq": <<A Sequence Number, 95, 192 etc, Larger than above (Must be in increasing seq order>>
#					"title": "Restart Failed",
#					"body": "Tried to just restart server - it failed."
#				},
#          ]
#		}
#   ]
# }
#
#--------------------------------------------------------------------------------------------------------
# /api/v1/get-issue-details - get an issue with all of its notes
# @get('/api/v1/get-issue-detail')
@app.route('/api/v1/get-issue-detail', method=['OPTIONS', 'GET', 'POST'])
def get_issue_detail():
   
    response.content_type = "application/json"
    dict = parse_qs(request.query_string)
    if not required_param(dict,["issue_id"]) :
        return
    issue_id = lower(dict["issue_id"][0])

    issue_data = run_select_raw ( "select * from i_issue where id = %(issue_id)s", { "issue_id":issue_id } )

    issue_result = issue_data["result"]

    if issue_data["n_rows"] == 1 :
        # might have notes
        nr = 1
        note_data = run_select_raw ( "select * from i_note where issue_id = %(issue_id)s order by seq", {"issue_id":issue_id } )
        issue_result[0]["note"] = note_data["result"]
        issue_result[0]["n_rows_note"] = note_data["n_rows"]
    else :
        # no note
        nr = 0
        issue_result[0]["note"] = []
        issue_result[0]["n_rows_note"] = 0

    ss = json.dumps(
        issue_result,
        sort_keys=True,
        indent=1,
        default=default 
    )

    return "{"+"\"status\":\"success\",\"n_rows\":{},\"data\":{}".format(nr,ss)+"}"

        
    
    
    
#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
#  Given an issue_id and a new node, associate the note (insert) with the issue.
#--------------------------------------------------------------------------------------------------------
# /api/add-note-to-issue
# @get('/api/v1/add-note-to-issue')
@app.route('/api/v1/add-note-to-issue', method=['OPTIONS', 'GET', 'POST'])
def create_note():
    return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"

#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
#  Given a note_id, delete that note from the associated i_issue.
#--------------------------------------------------------------------------------------------------------
# /api/upd-note
# @get('/api/v1/update-note')
@app.route('/api/v1/delete-note', method=['OPTIONS', 'GET', 'POST'])
def update_note():
    return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"

#--------------------------------------------------------------------------------------------------------
# Assignment 04
#--------------------------------------------------------------------------------------------------------
#  Given an issue_id and a severity_id (requried parameters) update the issue with a new severity_id
#--------------------------------------------------------------------------------------------------------
# /api/update-severity
# @get('/api/v1/update-severity')
@app.route('/api/v1/update-severity', method=['OPTIONS', 'GET', 'POST'])
def upd_severity():
    return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"





# /api/upd-state
# @get('/api/v1/update-state')
@app.route('/api/v1/update-state', method=['OPTIONS', 'GET', 'POST'])
def upd_state():
    global db_conn
    response.content_type = "application/json"
    if request.method == 'GET':
        dict = parse_qs(request.query_string)
    elif request.method == 'POST':
        dict = {}
        for key, value in request.forms.items():
            print("For name " + key + ", the value is " + value)
            dict[key] = [value]
    if not required_param(dict,["state_id","issue_id"]):
        return
    state_id = dict["state_id"][0]
    issue_id = dict["issue_id"][0]
    s = run_update ( "update i_issue set state_id = %(state_id)s where id = %(issue_id)s", { "state_id":state_id, "issue_id":issue_id } )
    db_conn.commit()
    return s

# @get('/api/v1/get-state')
@app.route('/api/v1/get-state', method=['OPTIONS', 'GET'])
def get_state():
    response.content_type = "application/json"
    return run_select ( "SELECT * FROM i_state", {})

# @get('/api/v1/get-severity')
@app.route('/api/v1/get-severity', method=['OPTIONS', 'GET'])
def get_severity():
    response.content_type = "application/json"
    return run_select ( "SELECT * FROM i_severity", {})



@app.route('/api/v1/note', method=['OPTIONS', 'DELETE'])
def delete_note():
    response.content_type = "application/json"
    dict = parse_qs(request.query_string)
    if not required_param(dict,["note_id"]) :
        return
    note_id = lower(dict["note_id"][0])
    return run_delete ( "DELETE FROM i_note WHERE id = %(id)s", { "id": note_id })

@app.route('/api/v1/note', method=['OPTIONS', 'PUT'])
def update_note():
    response.content_type = "application/json"
    dict = parse_qs(request.query_string)
    if not required_param(dict,["note_id", "title", "body"]) :
        return
    note_id = lower(dict["note_id"][0])
    title = lower(dict["title"][0])
    body = lower(dict["body"][0])
    return run_update ( "UPDATE i_note SET title = %(title)s, body = %(body)s WHERE id = %(id)s", { "id": note_id })

@app.route('/api/v1/get-note', method=['OPTIONS', 'GET'])
def update_note():
    response.content_type = "application/json"
    dict = parse_qs(request.query_string)
    note_id = lower(dict["note_id"][0])
    issue_id = lower(dict["issue_id"][0])
    if note_id == "" and issue_id == "" :
        abort(406, "Missing {} from parameters".format(item))
        return
    if note_id == "" :
        return run_select ( "SELECT * FROM i_note WHERE issue_id = %(id)s order by seq", { "id": issue_id })
    else:
        return run_select ( "SELECT * FROM i_note WHERE id = %(id)s", { "id": note_id })







#################################################################################################################################
# File Server
#################################################################################################################################

@app.route('/')
def server_index_html():
    global root_dir
    return static_file("/index.html", root=root_dir)

@app.route('/<filepath:path>')
def server_static(filepath):
    global root_dir
    return static_file(filepath, root=root_dir)

@app.error(404)
def error404(error):
    return '404 error - nothing here, sorry'






#################################################################################################################################
# Main Program
#################################################################################################################################

app_config = None

if __name__ == '__main__':
    try:
        app_config = config(filename='app_config.ini', section='app')
        connect()

        root_dir = app_config["static_files"]
        xhost = app_config["host"]
        xport = app_config["port"]

        cwd = os.getcwd()
        if root_dir[0] != '/' :
            # root_dir = cwd + "/" + root_dir 
            root_dir = os.path.join(cwd, root_dir)
            # print ( "root_dir={}".format(root_dir) )
        root_dir = os.path.normpath(root_dir)

        app.install(EnableCors())
        app.run(port=xport, host=xhost, debug=True) # app.run(port=12128, host='0.0.0.0', debug=True)

        disconnect()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)
        disconnect()
    finally:
        disconnect()


