  1: #!/Users/philip/opt/anaconda3/bin/python
  2: #!/use/bin//python3
  3: 
  4: import bottle
  5: # from bottle import get, route, static_file, run, error, response, request, abort, put, delete, post, app
  6: from bottle import error, response, request, abort, static_file
  7: import psycopg2
  8: import datetime
  9: import os
 10: from config import config
 11: from urllib.parse import parse_qs
 12: import json
 13: import uuid
 14:         
 15: cwd = ""
 16: root_dir = './www'
 17: app = bottle.app()
 18: 
 19: 
 20: #################################################################################################################################
 21: #################################################################################################################################
 22: class EnableCors(object):
 23:     name = 'enable_cors'
 24:     api = 2
 25: 
 26:     def apply(self, fn, context):
 27:         def _enable_cors(*args, **kwargs):
 28:             # set CORS headers
 29:             response.headers['Access-Control-Allow-Origin'] = '*'
 30:             response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
 31:             response.headers['Access-Control-Allow-Headers'] = 'Origin, Accept, Content-Type, X-Requested-With, X-CSRF-Token'
 32: 
 33:             if bottle.request.method != 'OPTIONS':
 34:                 # actual request; reply with the actual response
 35:                 return fn(*args, **kwargs)
 36: 
 37:         return _enable_cors
 38: 
 39: 
 40: #################################################################################################################################
 41: # General Suppot Functions
 42: #################################################################################################################################
 43: def gen_uuid():
 44:     u = "{}".format(uuid.uuid4())
 45:     return u
 46: 
 47: def required_param( param, req ):
 48:     # print ( "param={} req={}".format ( param, req ) )
 49:     for item in req:
 50:         # print ( "item={}".format(item) )
 51:         if not ( item in param ) :
 52:             # print ( "Error occuring, missing {} parameter".format(item))
 53:             abort(406, "Missing {} from parameters".format(item))
 54:             return False
 55:     return True
 56: 
 57: #################################################################################################################################
 58: # Database Interface
 59: #################################################################################################################################
 60: 
 61: db_conn = None
 62: db_connection_info = None
 63: db_version_str = ""
 64: 
 65: def connect():
 66:     """ Connect to the PostgreSQL database server """
 67:     global db_conn
 68:     global db_connection_info
 69:     db_conn = None
 70:     param = None
 71:     try:
 72:         db_connection_info = config() # read database connection parameters
 73:         # print ( "db_connetion_info = {}".format(db_connection_info ) )
 74: 
 75:         # connect to the PostgreSQL server
 76:         print('Connecting to the PostgreSQL database...')
 77:         db_conn = psycopg2.connect(**db_connection_info)
 78:         
 79:         cur = db_conn.cursor()              
 80:         cur.execute('SELECT 123 as "x"')
 81:         t = cur.fetchone()
 82:         # print ( "t={}".format(t) )
 83:         cur.close()
 84:        
 85:     except (Exception, psycopg2.DatabaseError) as error:
 86:         print(error)
 87: 
 88: def disconnect():
 89:     global db_conn
 90:     if db_conn is not None:
 91:         db_conn.close() # close the communication with the PostgreSQL
 92:         db_conn = None
 93: 
 94: def default(o):
 95:     if isinstance(o, (datetime.date, datetime.datetime)):
 96:         return o.isoformat()
 97: 
 98: def create_dict(obj, fields):
 99:     mappings = dict(zip(fields, obj))
100:     return mappings
101: 
102: def run_select ( stmt, data ):
103:     global db_conn
104:     cur = None
105:     try:
106:         cur = db_conn.cursor()                      # create a cursor
107:         cur.execute(stmt, data)
108:         colnames = [desc[0] for desc in cur.description]
109:         #d# print ( "colnames={}".format ( colnames ) )
110:         rows = cur.fetchall()
111:         n_rows = cur.rowcount
112:         result = []
113:         for row in rows:
114:             result.append(create_dict(row, colnames)) 
115:         cur.close()
116: 
117:         ss = json.dumps(
118:           result,
119:           sort_keys=True,
120:           indent=1,
121:           default=default
122:         )
123: 
124:         return "{"+"\"status\":\"success\",\"n_rows\":{},\"data\":{}".format(n_rows,ss)+"}"
125: 
126:     except (Exception, psycopg2.DatabaseError) as error:
127:         print ( "Database Error {}".format(error) )
128:         return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
129:     finally:
130:         if cur is not None:
131:             cur.close()
132:     
133: def run_select_raw ( stmt, data ):
134:     global db_conn
135:     cur = None
136:     try:
137:         cur = db_conn.cursor()                      # create a cursor
138:         cur.execute(stmt, data)
139:         colnames = [desc[0] for desc in cur.description]
140:         #d# print ( "colnames={}".format ( colnames ) )
141:         rows = cur.fetchall()
142:         n_rows = cur.rowcount
143:         result = []
144:         for row in rows:
145:             result.append(create_dict(row, colnames)) 
146:         cur.close()
147: 
148:         ss = json.dumps(
149:           result,
150:           sort_keys=True,
151:           indent=1,
152:           default=default
153:         )
154: 
155:         datarv = {
156:             "status": "success",
157:             "result": result,
158:             "n_rows": n_rows,
159:             "column_names": colnames,
160:             "rows": rows,
161:             "json_str": ss
162:         }
163: 
164:         # print ( "return data is {}".format(datarv) )
165: 
166:         db_conn.commit()
167:         return datarv
168: 
169:     except (Exception, psycopg2.DatabaseError) as error:
170:         print ( "Database Error {}".format(error) )
171:         datarv = {
172:             "status": "error",
173:             "msg": "{}".format(error)
174:         }
175:         db_conn.commit()
176:         return datarv
177:     finally:
178:         if cur is not None:
179:             cur.close()
180:    
181:  
182: def run_insert ( stmt, data ) :
183:     global db_conn
184:     cur = None
185:     try:
186:         cur = db_conn.cursor()                      # create a cursor
187:         cur.execute(stmt, data)
188:         cur.close()
189:         return "{"+"\"status\":\"success\",\"id\":\"{}\"".format(data["id"])+"}"
190: 
191:     except (Exception, psycopg2.DatabaseError) as error:
192:         return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
193:     finally:
194:         if cur is not None:
195:             cur.close()
196:     
197: def run_update ( stmt, data ) :
198:     global db_conn
199:     cur = None
200:     try:
201:         cur = db_conn.cursor()                      # create a cursor
202:         cur.execute(stmt, data)
203:         rowcount = cur.rowcount
204:         cur.close()
205: 
206:         return "{"+"\"status\":\"success\",\"n_rows\":{}".format(rowcount)+"}"
207: 
208:     except (Exception, psycopg2.DatabaseError) as error:
209:         return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
210:     finally:
211:         if cur is not None:
212:             cur.close()
213:     
214: def run_delete ( stmt, data ) :
215:     global db_conn
216:     cur = None
217:     try:
218:         cur = db_conn.cursor()                      # create a cursor
219:         cur.execute(stmt, data)
220:         rowcount = cur.rowcount
221:         cur.close()
222:         return "{"+"\"status\":\"success\",\"n_rows\":{}".format(rowcount)+"}"
223: 
224:     except (Exception, psycopg2.DatabaseError) as error:
225:         return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
226:     finally:
227:         if cur is not None:
228:             cur.close()
229: 
230:     
231: 
232: 
233: 
234: #################################################################################################################################
235: # Routes 
236: #################################################################################################################################
237: 
238: # @get('/api/v1/hello')
239: @app.route('/api/v1/hello', method=['OPTIONS', 'GET'])
240: def hello():
241:     response.content_type = "application/json"
242:     return "{\"msg\":\"hello world\"}"
243: 
244: # @get('/api/v1/global-data.js')
245: @app.route('/api/v1/global-data.js', method=['OPTIONS', 'GET'])
246: def global_data():
247:     response.content_type = "text/javascript;charset=UTF-8"
248:     s1 = run_select ( "SELECT * FROM i_state", {})
249:     s2 = run_select ( "SELECT * FROM i_severity", {})
250:     return "var g_state = {s1};\n\nvar g_severity = {s2};\n\n".format( s1 = s1, s2 = s2 );
251:     
252: 
253: 
254: 
255: 
256: 
257: # @get('/api/v1/status')
258: @app.route('/api/v1/status', method=['OPTIONS', 'GET'])
259: def status():
260:     response.content_type = "application/json"
261:     cur = None
262:     dict = {}
263:     if request.method == 'GET':
264:         dict = parse_qs(request.query_string)
265:     try:
266:         cur = db_conn.cursor()              
267:         cur.execute('SELECT \'Database-OK\' as "x"')
268:         t = cur.fetchone()
269:         # print ( "server status t={}".format(t) )
270:         cur.close()
271:         db_conn.commit()
272:         # return "{"+"\"status\":\"success\",\"server_status\":\"Server-OK\",\"database_status\":\"{}\"".format(t[0])+"}"
273:         ss = json.dumps(
274:           dict,
275:           sort_keys=True,
276:           indent=1,
277:           default=default
278:         )
279:         return "{"+"\"status\":\"success\",\"server_status\":\"Server-OK\",\"database_status\":\"{}\",\"params\":{}".format(t[0],ss)+"}"
280:     except (Exception, psycopg2.DatabaseError) as error:
281:         return "{"+"\"status\":\"error\",\"msg\":\"{}\"".format(error)+"}"
282:     finally:
283:         if cur is not None:
284:             cur.close()
285: 
286: # @get('/status')
287: @app.route('/status', method=['OPTIONS', 'GET'])
288: def status_2():
289:     return status()
290: 
291: # @get('/api/v1/db-version')
292: @app.route('/api/v1/db-version', method=['OPTIONS', 'GET'])
293: def db_version():
294:     response.content_type = "application/json"
295:     global db_version_str
296:     if db_version_str == "" or db_version_str == None:
297:         db_version_str = run_select ( 'SELECT version()', {} )
298:     db_conn.commit()
299:     return db_version_str
300: 
301: # @get('/api/v1/search-keyword')
302: @app.route('/api/v1/search-keyword', method=['OPTIONS', 'GET'])
303: def search_keyword():
304:     response.content_type = "application/json"
305:     dict = parse_qs(request.query_string)
306:     if not required_param(dict,["kw"]):
307:         return
308:     kw = dict["kw"]
309:     # print ( "kw={}".format( kw ) )
310:     lang = 'english'
311:     try:
312:         cur = db_conn.cursor()              
313:         cur.execute('SELECT value FROM i_config where name = \'language\'')
314:         t = cur.fetchone()
315:         # print ( "server status t={} t[0]=->{}<-".format(t, t[0]) )
316:         lang = t[0]
317:         cur.close()
318:         db_conn.commit()
319:     except (Exception, psycopg2.DatabaseError) as error:
320:         lang = 'english'
321:     finally:
322:         if cur is not None:
323:             cur.close()
324:     # return run_select ( "SELECT * FROM i_issue_st_sv where words @@ to_tsquery('english'::regconfig,%(kw)s)", { "kw":kw[0] } )
325:     return run_select ( "SELECT * FROM i_issue_st_sv where words @@ to_tsquery('{}'::regconfig,%(kw)s)".format(lang), { "kw":kw[0] } )
326: 
327: 
328: # @get('/api/v1/get-config')
329: @app.route('/api/v1/get-config', method=['OPTIONS', 'GET'])
330: def get_config():
331:     response.content_type = "application/json"
332:     return run_select ( "SELECT * FROM i_config", {})
333: 
334: #--------------------------------------------------------------------------------------------------------
335: # Assignment 04
336: #--------------------------------------------------------------------------------------------------------
337: #   use `run_select ( "SELECT * FROM i_issue_st_sv", {})`    
338: #  to select back the set of issues  in the database         
339: #  that are not `Deleted`.   Create the view i_issue_st_sv   
340: #  to join from i_issue to i_state and i_severity so that    
341: #  both the state_id and the state are returned (this is the i_issue_st_sv view).  Sort the   
342: #  data into descending severity_id, and descending creation 
343: #  and update  dates.   The view i_issue_st_sv should be     
344: #  added to your data model that you turn in.                
345: #--------------------------------------------------------------------------------------------------------
346: # /api/issue-list
347: # @get('/api/v1/issue-list')
348: @app.route('/api/v1/issue-list', method=['OPTIONS', 'GET'])
349: def issue_list():
350:     return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"
351: 
352: 
353: #--------------------------------------------------------------------------------------------------------
354: # Assignment 04
355: #--------------------------------------------------------------------------------------------------------
356: #  perfom an insert into i_issue with parameters from the GET or POST.             
357: # The paramters should require 'body' and 'title' but allow for                  
358: # defaults for "severity_id" and "issue_id" .  These should default              
359: # to '1' for the first ID in the set of ids.                                     
360: # For "issue_id" it should default to a new UUID if not specified.              
361: # Use `run_insert` do to the insert and remember to commit the                   
362: # change to the database.  The return from `run_insert` will                    
363: # have the status/success and ID to return to the client                       
364: # application.                                                                
365: #--------------------------------------------------------------------------------------------------------
366: # /api/create-issue
367: # @get('/api/v1/create-issue')
368: @app.route('/api/v1/create-issue', method=['POST', 'GET', 'OPTIONS'])
369: def create_issue():
370:     return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"
371: 
372: 
373: #--------------------------------------------------------------------------------------------------------
374: # Assignment 04
375: #--------------------------------------------------------------------------------------------------------
376: # Use a passed 'issue_id' to do a delete from it i_issue table.                  
377: #--------------------------------------------------------------------------------------------------------
378: # /api/delete-issue
379: # @get('/api/v1/delete-issue')
380: @app.route('/api/v1/delete-issue', method=['OPTIONS', 'GET', 'POST'])
381: def delete_issue():
382:     return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"
383: 
384: #--------------------------------------------------------------------------------------------------------
385: # Assignment 04
386: #--------------------------------------------------------------------------------------------------------
387: #  Take as input the issue_id, the title, the body and optionally a new severity_id and a new state_id
388: # and update the i_issue rowo specified by the issue_id.
389: #--------------------------------------------------------------------------------------------------------
390: # /api/update-issue
391: # @get('/api/v1/update-issue')
392: @app.route('/api/v1/update-issue', method=['OPTIONS', 'GET', 'POST'])
393: def update_issue():
394:     return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"
395: 
396: 
397: #--------------------------------------------------------------------------------------------------------
398: # Assignment 04
399: #--------------------------------------------------------------------------------------------------------
400: #  Return a set of data from i_issue (or i_issue_st_sv would be more accurate) with all of the assocated
401: # notes for the issue.  This is the data that is used to paint the issue detail page.
402: #
403: # If you have an issue with:
404: #        title == "Ho - The Server is Broken"
405: #        body == "Yes this is true... The sever is down - not working. Getting error 52114"
406: #        severity_id,severity == 7, 'Severe - System down'
407: #        state_id,state == 2, 'Verified'
408: # And it has 2 notes:
409: #      1)
410: #          i_note.title == "I verified that it is true."
411: #          i_note.body == "Yes the server is down"
412: #      2)
413: #          i_note.title == "Restart Failed"
414: #          i_note.body == "Tried to just restart server - it failed."
415: #
416: # Then The JSON data returned would be (Note the order of the fields will be different):
417: #
418: # {
419: #   "status": "success"
420: #   "data": [
421: #        {
422: #          "id":  "<< Some UUID >>",
423: #          "title": "Ho - The Server is Broken",
424: #          "body": "Yes this is true... The sever is down - not working. Getting error 52114",
425: #          "state": "Verified",
426: #          "state_id": 2,
427: #          "severity": "Severe - System down"
428: #          "severity_id": 7,
429: #          "updated": "<< Some Timestamp data, might be null >>",
430: #          "created": "<< A created timestamp >>",
431: #            "n_rows_note": 2,
432: #            "note": [
433: #                {
434: #                    "id": "<< A Different UUID >>",
435: #                    "issue_id": "<< Some UUID (same as the i_issue UUID) >>",
436: #                    "seq": <<A Sequence Number, 55, 88 etc>>,
437: #                    "title": "I verified that it is true.",
438: #                    "body": "Yes the server is down"
439: #                },
440: #                {
441: #                    "id": "<< A 2nd Different UUID >>",
442: #                    "issue_id": "<< Some UUID (same as the i_issue UUID) >>",
443: #                    "seq": <<A Sequence Number, 95, 192 etc, Larger than above (Must be in increasing seq order>>
444: #                    "title": "Restart Failed",
445: #                    "body": "Tried to just restart server - it failed."
446: #                },
447: #          ]
448: #        }
449: #   ]
450: # }
451: #
452: #--------------------------------------------------------------------------------------------------------
453: # /api/v1/get-issue-details - get an issue with all of its notes
454: # @get('/api/v1/get-issue-detail')
455: @app.route('/api/v1/get-issue-detail', method=['OPTIONS', 'GET', 'POST'])
456: def get_issue_detail():
457:    
458:     response.content_type = "application/json"
459:     dict = parse_qs(request.query_string)
460:     if not required_param(dict,["issue_id"]) :
461:         return
462:     issue_id = lower(dict["issue_id"][0])
463: 
464:     issue_data = run_select_raw ( "select * from i_issue where id = %(issue_id)s", { "issue_id":issue_id } )
465: 
466:     issue_result = issue_data["result"]
467: 
468:     if issue_data["n_rows"] == 1 :
469:         # might have notes
470:         nr = 1
471:         note_data = run_select_raw ( "select * from i_note where issue_id = %(issue_id)s order by seq", {"issue_id":issue_id } )
472:         issue_result[0]["note"] = note_data["result"]
473:         issue_result[0]["n_rows_note"] = note_data["n_rows"]
474:     else :
475:         # no note
476:         nr = 0
477:         issue_result[0]["note"] = []
478:         issue_result[0]["n_rows_note"] = 0
479: 
480:     ss = json.dumps(
481:         issue_result,
482:         sort_keys=True,
483:         indent=1,
484:         default=default 
485:     )
486: 
487:     return "{"+"\"status\":\"success\",\"n_rows\":{},\"data\":{}".format(nr,ss)+"}"
488: 
489:         
490:     
491:     
492:     
493: #--------------------------------------------------------------------------------------------------------
494: # Assignment 04
495: #--------------------------------------------------------------------------------------------------------
496: #  Given an issue_id and a new node, associate the note (insert) with the issue.
497: #--------------------------------------------------------------------------------------------------------
498: # /api/add-note-to-issue
499: # @get('/api/v1/add-note-to-issue')
500: @app.route('/api/v1/add-note-to-issue', method=['OPTIONS', 'GET', 'POST'])
501: def create_note():
502:     return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"
503: 
504: #--------------------------------------------------------------------------------------------------------
505: # Assignment 04
506: #--------------------------------------------------------------------------------------------------------
507: #  Given a note_id, delete that note from the associated i_issue.
508: #--------------------------------------------------------------------------------------------------------
509: # /api/upd-note
510: # @get('/api/v1/update-note')
511: @app.route('/api/v1/delete-note', method=['OPTIONS', 'GET', 'POST'])
512: def update_note():
513:     return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"
514: 
515: #--------------------------------------------------------------------------------------------------------
516: # Assignment 04
517: #--------------------------------------------------------------------------------------------------------
518: #  Given an issue_id and a severity_id (requried parameters) update the issue with a new severity_id
519: #--------------------------------------------------------------------------------------------------------
520: # /api/update-severity
521: # @get('/api/v1/update-severity')
522: @app.route('/api/v1/update-severity', method=['OPTIONS', 'GET', 'POST'])
523: def upd_severity():
524:     return "{"+"\"status\":\"TODO\",\"n_rows\":0,\"data\":[]"+"}"
525: 
526: 
527: 
528: 
529: 
530: # /api/upd-state
531: # @get('/api/v1/update-state')
532: @app.route('/api/v1/update-state', method=['OPTIONS', 'GET', 'POST'])
533: def upd_state():
534:     global db_conn
535:     response.content_type = "application/json"
536:     if request.method == 'GET':
537:         dict = parse_qs(request.query_string)
538:     elif request.method == 'POST':
539:         dict = {}
540:         for key, value in request.forms.items():
541:             print("For name " + key + ", the value is " + value)
542:             dict[key] = [value]
543:     if not required_param(dict,["state_id","issue_id"]):
544:         return
545:     state_id = dict["state_id"][0]
546:     issue_id = dict["issue_id"][0]
547:     s = run_update ( "update i_issue set state_id = %(state_id)s where id = %(issue_id)s", { "state_id":state_id, "issue_id":issue_id } )
548:     db_conn.commit()
549:     return s
550: 
551: # @get('/api/v1/get-state')
552: @app.route('/api/v1/get-state', method=['OPTIONS', 'GET'])
553: def get_state():
554:     response.content_type = "application/json"
555:     return run_select ( "SELECT * FROM i_state", {})
556: 
557: # @get('/api/v1/get-severity')
558: @app.route('/api/v1/get-severity', method=['OPTIONS', 'GET'])
559: def get_severity():
560:     response.content_type = "application/json"
561:     return run_select ( "SELECT * FROM i_severity", {})
562: 
563: 
564: 
565: @app.route('/api/v1/note', method=['OPTIONS', 'DELETE'])
566: def delete_note():
567:     response.content_type = "application/json"
568:     dict = parse_qs(request.query_string)
569:     if not required_param(dict,["note_id"]) :
570:         return
571:     note_id = lower(dict["note_id"][0])
572:     return run_delete ( "DELETE FROM i_note WHERE id = %(id)s", { "id": note_id })
573: 
574: @app.route('/api/v1/note', method=['OPTIONS', 'PUT'])
575: def update_note():
576:     response.content_type = "application/json"
577:     dict = parse_qs(request.query_string)
578:     if not required_param(dict,["note_id", "title", "body"]) :
579:         return
580:     note_id = lower(dict["note_id"][0])
581:     title = lower(dict["title"][0])
582:     body = lower(dict["body"][0])
583:     return run_update ( "UPDATE i_note SET title = %(title)s, body = %(body)s WHERE id = %(id)s", { "id": note_id })
584: 
585: @app.route('/api/v1/get-note', method=['OPTIONS', 'GET'])
586: def update_note():
587:     response.content_type = "application/json"
588:     dict = parse_qs(request.query_string)
589:     note_id = lower(dict["note_id"][0])
590:     issue_id = lower(dict["issue_id"][0])
591:     if note_id == "" and issue_id == "" :
592:         abort(406, "Missing {} from parameters".format(item))
593:         return
594:     if note_id == "" :
595:         return run_select ( "SELECT * FROM i_note WHERE issue_id = %(id)s order by seq", { "id": issue_id })
596:     else:
597:         return run_select ( "SELECT * FROM i_note WHERE id = %(id)s", { "id": note_id })
598: 
599: 
600: 
601: 
602: 
603: 
604: 
605: #################################################################################################################################
606: # File Server
607: #################################################################################################################################
608: 
609: @app.route('/')
610: def server_index_html():
611:     global root_dir
612:     return static_file("/index.html", root=root_dir)
613: 
614: @app.route('/<filepath:path>')
615: def server_static(filepath):
616:     global root_dir
617:     return static_file(filepath, root=root_dir)
618: 
619: @app.error(404)
620: def error404(error):
621:     return '404 error - nothing here, sorry'
622: 
623: 
624: 
625: 
626: 
627: 
628: #################################################################################################################################
629: # Main Program
630: #################################################################################################################################
631: 
632: app_config = None
633: 
634: if __name__ == '__main__':
635:     try:
636:         app_config = config(filename='app_config.ini', section='app')
637:         connect()
638: 
639:         root_dir = app_config["static_files"]
640:         xhost = app_config["host"]
641:         xport = app_config["port"]
642: 
643:         cwd = os.getcwd()
644:         if root_dir[0] != '/' :
645:             # root_dir = cwd + "/" + root_dir 
646:             root_dir = os.path.join(cwd, root_dir)
647:             # print ( "root_dir={}".format(root_dir) )
648:         root_dir = os.path.normpath(root_dir)
649: 
650:         app.install(EnableCors())
651:         app.run(port=xport, host=xhost, debug=True) # app.run(port=12128, host='0.0.0.0', debug=True)
652: 
653:         disconnect()
654:     except (Exception, psycopg2.DatabaseError) as error:
655:         print(error)
656:         disconnect()
657:     finally:
658:         disconnect()
659: 
660: 
