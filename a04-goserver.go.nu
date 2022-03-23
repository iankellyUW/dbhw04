  1: package main
  2: 
  3: import (
  4:     "context"
  5:     "fmt"
  6:     "log"
  7:     "net/http"
  8:     "os"
  9:     "time"
 10: 
 11:     "github.com/georgysavva/scany/pgxscan"
 12:     "github.com/jackc/pgx/v4/pgxpool"
 13:     "github.com/pschlump/MiscLib"
 14:     "github.com/pschlump/filelib"
 15:     "go.uber.org/zap"
 16: )
 17: 
 18: // These are the values pulled in from ./cfg.json file.
 19: type GlobalConfig struct {
 20:     StaticPath string `json:"static_files"`
 21:     Host       string
 22:     Port       string
 23:     DbFlags    []string `json:"db_flags"`
 24: }
 25: 
 26: var gCfg GlobalConfig
 27: var DbOn map[string]bool = make(map[string]bool)
 28: var sugar *zap.SugaredLogger
 29: 
 30: // Database Context and Connection
 31: var conn *pgxpool.Pool
 32: var ctx context.Context
 33: 
 34: func main() {
 35: 
 36:     // --------------------------------------------------------------------------------------
 37:     // Read global config
 38:     // --------------------------------------------------------------------------------------
 39:     ReadJson("cfg.json", &gCfg)
 40:     if len(gCfg.DbFlags) > 0 {
 41:         for _, x := range gCfg.DbFlags {
 42:             DbOn[x] = true
 43:         }
 44:     }
 45: 
 46:     if DbOn["dump-global-config"] {
 47:         fmt.Printf("Global Config:%s\n", SVarI(gCfg))
 48:     }
 49: 
 50:     // --------------------------------------------------------------------------------------
 51:     // Setup Logging
 52:     // --------------------------------------------------------------------------------------
 53:     os.MkdirAll("./log", 0755)
 54:     logFp, err := filelib.Fopen("./log/log.out", "a")
 55:     if err != nil {
 56:         fmt.Fprintf(os.Stderr, "Unable to open ./log/log.out for loging/append, error:%s\n", err)
 57:         os.Exit(1)
 58:     }
 59:     sugar = LogInit(DbOn["debug-log"], logFp)
 60: 
 61:     // --------------------------------------------------------------------------------------
 62:     // Connect to database - if we get to the defer then we have successfuly connected.
 63:     // --------------------------------------------------------------------------------------
 64:     ConnectToDb()
 65:     defer DisConnectToDb()
 66: 
 67:     // --------------------------------------------------------------------------------------
 68:     // Routes
 69:     // --------------------------------------------------------------------------------------
 70:     mux := http.NewServeMux()
 71:     mux.Handle("/api/v1/hello", http.HandlerFunc(HandleHelloWorld))
 72:     mux.Handle("/api/v1/global-data.js", http.HandlerFunc(HandleApiV1GlobalData))
 73:     mux.Handle("/api/v1/status", http.HandlerFunc(HandleStatus))
 74:     mux.Handle("/status", http.HandlerFunc(HandleStatus))
 75:     mux.Handle("/api/v1/db-version", http.HandlerFunc(HandleApiV1DbVersion))
 76:     mux.Handle("/api/v1/get-config", http.HandlerFunc(HandleApiV1GetConfig))
 77:     mux.Handle("/api/v1/search-keyword", http.HandlerFunc(HandleApiV1SearchKeyword))
 78:     mux.Handle("/api/v1/issue-list", http.HandlerFunc(HandleApiV1IssueList))
 79:     mux.Handle("/api/v1/create-issue", http.HandlerFunc(HandleApiV1CreateIssue))
 80:     mux.Handle("/api/v1/delete-issue", http.HandlerFunc(HandleApiV1DeleteIssue))
 81:     mux.Handle("/api/v1/get-severity", http.HandlerFunc(HandleApiV1GetSeverity))
 82:     mux.Handle("/api/v1/get-state", http.HandlerFunc(HandleApiV1GetState))
 83:     mux.Handle("/api/v1/add-note-to-issue", http.HandlerFunc(HandleApiV1AddNoteToIssue))
 84:     mux.Handle("/api/v1/get-note", http.HandlerFunc(HandleApiV1GetNote))
 85:     mux.Handle("/api/v1/update-issue", http.HandlerFunc(HandleApiV1UpdateIssue))
 86:     mux.Handle("/api/v1/delete-note", http.HandlerFunc(HandleApiV1DeleteNote))
 87:     mux.Handle("/api/v1/update-severity", http.HandlerFunc(HandleApiV1UpdateSeverity))
 88:     mux.Handle("/api/v1/update-state", http.HandlerFunc(HandleApiV1UpdateState))
 89:     mux.Handle("/api/v1/get-issue-detail", http.HandlerFunc(HandleApiV1GetIssueDetail))
 90: 
 91:     // --------------------------------------------------------------------------------------
 92:     // server static files.
 93:     // --------------------------------------------------------------------------------------
 94:     {
 95:         Dir := gCfg.StaticPath
 96:         if DbOn["print.static.path"] {
 97:             fmt.Printf("%sPath: %s%s\n", MiscLib.ColorYellow, Dir, MiscLib.ColorReset)
 98:         }
 99:         fs := http.FileServer(http.Dir(Dir))
100:         fx := func(www http.ResponseWriter, req *http.Request) {
101:             www.Header().Set("Cache-Control", "public, max-age=1")
102:             fs.ServeHTTP(www, req)
103:         }
104:         mux.Handle("/", http.HandlerFunc(fx))
105:     }
106: 
107:     // --------------------------------------------------------------------------------------
108:     // start server.
109:     // --------------------------------------------------------------------------------------
110:     svr := http.Server{
111:         Addr:    gCfg.Host + ":" + gCfg.Port,
112:         Handler: ApacheLogger(CORSMiddleware(mux)),
113:     }
114:     log.Fatal(svr.ListenAndServe())
115: }
116: 
117: // ----------------------------------------------------------- Structs for SQL  -----------------------------------------------------------------
118: 
119: /*
120: CREATE table i_note (
121:     id                     uuid default uuid_generate_v4() not null primary key,
122:     issue_id             uuid not null,
123:     seq                 serial not null,
124:     title                 text not null,
125:     body                 text not null,
126:     words                tsvector,
127:     updated             timestamp,
128:     created             timestamp default current_timestamp not null
129: );
130: */
131: type I_Note struct {
132:     Id       string `json:"id"`
133:     Issue_id string `json:"issue_id"`
134:     Seq      int    `json":"seq"`
135:     Title    string `json:"title"`
136:     Body     string `json:"body"`
137: }
138: 
139: // "github.com/jackc/pgtype"
140: // See: https://github.com/georgysavva/scany/blob/master/pgxscan/pgxscan_test.go
141: 
142: //CREATE table if not exists i_state (
143: //    id serial not null primary key,
144: //    state text not null
145: //);
146: type I_State struct {
147:     Id    int    `json:"id"`
148:     State string `json:"state"`
149: }
150: 
151: //CREATE table if not exists i_severity (
152: //    id serial not null primary key,
153: //    severity text not null
154: //);
155: type I_Severity struct {
156:     Id       int    `json:"id"`
157:     Severity string `json:"severity"`
158: }
159: 
160: /*
161: CREATE OR REPLACE VIEW i_issue_st_sv AS
162:     select
163:           t1.id
164:         , t1.title
165:         , t1.body
166:         , t2.state
167:         , t1.state_id
168:         , t3.severity
169:         , t1.severity_id
170:         , t1.updated
171:         , t1.created
172:         , t1.words
173:     from i_issue as t1
174:         join i_state as t2 on ( t2.id = t1.state_id )
175:         join i_severity as t3 on ( t3.id = t1.severity_id )
176:     where t2.state != 'Deleted'
177:     order by t1.severity_id desc, t1.updated desc, t1.created desc
178: ;
179: */
180: type I_Issue_St_Sv struct {
181:     Id          string     `json:"id"`
182:     Title       string     `json:"title"`
183:     Body        string     `json:"body"`
184:     State       string     `json:"state"`
185:     State_id    int        `json:"state_id"`
186:     Severity    string     `json:"severity"`
187:     Severity_id int        `json:"severity_id"`
188:     Updated     *time.Time `json:"updated"`
189:     Created     *time.Time `json:"created"`
190:     Words       string
191: }
192: 
193: type I_Issue_And_Notes struct {
194:     Id          string     `json:"id"`
195:     Title       string     `json:"title"`
196:     Body        string     `json:"body"`
197:     State       string     `json:"state"`
198:     State_id    int        `json:"state_id"`
199:     Severity    string     `json:"severity"`
200:     Severity_id int        `json:"severity_id"`
201:     Updated     *time.Time `json:"updated"`
202:     Created     *time.Time `json:"created"`
203:     N_Notes     int        `json:"n_rows_note"`
204:     Notes       []*I_Note  `json:"note"`
205: }
206: 
207: type I_Config struct {
208:     Name  string `json:"name"`
209:     Value string `json:"value"`
210: }
211: 
212: type AString struct {
213:     Val string `json:"val"`
214: }
215: 
216: // ----------------------------------------------------------- Handlers -----------------------------------------------------------------
217: 
218: // HandleHelloWorld server to respond with "Hello World\n"
219: func HandleHelloWorld(www http.ResponseWriter, req *http.Request) {
220:     fmt.Fprintf(www, "Hello World\n")
221: }
222: 
223: // HandleStatus server to respond with a working message if up.
224: func HandleStatus(www http.ResponseWriter, req *http.Request) {
225:     www.WriteHeader(http.StatusOK) // 200
226:     var v []*AString
227:     stmt := "SELECT 'Database-OK' as \"val\""
228:     err := pgxscan.Select(ctx, conn, &v, stmt)
229:     if err != nil {
230:         LogSQLError(www, req, stmt, err)
231:         return
232:     }
233:     SetJsonHdr(www, req)
234:     if len(v) > 0 {
235:         fmt.Fprintf(www, `{"status":"success", "database":"ok", "req":%s}`, SVarI(req))
236:     } else {
237:         fmt.Fprintf(www, `{"status":"error", "database":"no-response","req":%s}`, SVarI(req))
238:     }
239:     return
240: }
241: 
242: // HandleApiV1GlobalData server to respond with a JavaScript file that has i_state and i_severity data in it as code.
243: func HandleApiV1GlobalData(www http.ResponseWriter, req *http.Request) {
244:     if req.Method == "GET" {
245:         // EnableCoors(www, req)
246:         var v1 []*I_State
247:         stmt := "SELECT * from i_state"
248:         err := pgxscan.Select(ctx, conn, &v1, stmt)
249:         if err != nil {
250:             LogSQLError(www, req, stmt, err)
251:             return
252:         }
253:         s1 := SVarI(v1)
254: 
255:         var v2 []*I_Severity
256:         err = pgxscan.Select(ctx, conn, &v2, "SELECT * from i_severity")
257:         if err != nil {
258:             LogSQLError(www, req, stmt, err)
259:             return
260:         }
261:         s2 := SVarI(v2)
262: 
263:         www.Header().Set("Content-Type", "text/javascript;charset=UTF-8")
264:         fmt.Fprintf(www, `
265: var g_state = %s;
266: 
267: var g_severity = %s;
268: `, s1, s2)
269:     } else {
270:         LogInvalidMethodError(www, req)
271:     }
272: }
273: 
274: // HandleApiV1GetConfig server to respoind with return data from i_config
275: func HandleApiV1GetConfig(www http.ResponseWriter, req *http.Request) {
276:     if req.Method == "GET" {
277:         var v1 []*I_Config
278:         stmt := "SELECT * from i_config"
279:         err := pgxscan.Select(ctx, conn, &v1, stmt)
280:         if err != nil {
281:             LogSQLError(www, req, stmt, err)
282:             return
283:         }
284:         fmt.Fprintf(www, "%s", StatusSuccess(SVarI(v1), www, req))
285:     } else {
286:         LogInvalidMethodError(www, req)
287:     }
288: }
289: 
290: // HandleApiV1DbVersion server to respoind with the version of the tabase as text.
291: // This is useful to verify that the database is up and the Go code is connecting
292: // to it.
293: func HandleApiV1DbVersion(www http.ResponseWriter, req *http.Request) {
294:     if req.Method == "GET" {
295:         var v []*AString
296:         stmt := "SELECT version() as \"val\""
297:         err := pgxscan.Select(ctx, conn, &v, stmt)
298:         if err != nil {
299:             LogSQLError(www, req, stmt, err)
300:             return
301:         }
302: 
303:         SetJsonHdr(www, req)
304:         if len(v) > 0 {
305:             fmt.Fprintf(www, "%s\n", v[0].Val)
306:         } else {
307:             fmt.Fprintf(www, "{\"error\":\"Unable to get version information\"}\n")
308:         }
309:     } else {
310:         LogInvalidMethodError(www, req)
311:     }
312: }
313: 
314: // HandleApiV1SearchKeyword server to perform a keyword search on i_issue.title and i_issue.body
315: // This uses a to_tsquery in the configured language (default english).   The data should be from
316: // the view i_issue_st_sv that joins i_issue with i_state and i_severity.
317: func HandleApiV1SearchKeyword(www http.ResponseWriter, req *http.Request) {
318:     if req.Method == "GET" || req.Method == "POST" {
319:         kw := GetParam("kw", www, req)
320:         if RequiredParam(www, req, "kw", kw) != nil {
321:             return
322:         }
323: 
324:         // Get the Language
325:         var v1 []*I_Config
326:         stmt := "SELECT Name, Value from i_config where name = 'language'"
327:         err := pgxscan.Select(ctx, conn, &v1, stmt)
328:         if err != nil {
329:             LogSQLError(www, req, stmt, err)
330:             return
331:         }
332:         lang := "english" // default to english
333:         if len(v1) >= 1 {
334:             lang = v1[0].Value
335:         }
336: 
337:         var v2 []*I_Issue_St_Sv
338:         stmt = "SELECT * FROM i_issue_st_sv where words @@ to_tsquery($1::regconfig,$2)"
339:         err = pgxscan.Select(ctx, conn, &v2, stmt, lang, kw)
340:         if err != nil {
341:             LogSQLError(www, req, stmt, err, lang, kw)
342:             return
343:         }
344: 
345:         fmt.Fprintf(www, "%s", StatusSuccess(SVarI(v2), www, req))
346:     } else {
347:         LogInvalidMethodError(www, req)
348:     }
349: }
350: 
351: // --------------------------------------------------------------------------------------------------------
352: //  Assignment 04
353: // --------------------------------------------------------------------------------------------------------
354: //    Use `pgxscan.Select ( "SELECT * FROM i_issue_st_sv", {})`
355: //   to select back the set of issues  in the database
356: //   that are not `Deleted`.   Create the view i_issue_st_sv
357: //   to join from i_issue to i_state and i_severity so that
358: //   both the state_id and the state are returned (this is the i_issue_st_sv view).  Sort the
359: //   data into descending severity_id, and descending creation
360: //   and update  dates.   The view i_issue_st_sv should be
361: //   added to your data model that you turn in.
362: // --------------------------------------------------------------------------------------------------------
363: 
364: // HandleApiV1IssueList server to respond with the data from the i_issue_st_sv view (i_issue).
365: func HandleApiV1IssueList(www http.ResponseWriter, req *http.Request) {
366:     if req.Method == "GET" {
367:         fmt.Fprintf(www, `{"status":"TODO"}`)
368:     } else {
369:         LogInvalidMethodError(www, req)
370:     }
371: }
372: 
373: // --------------------------------------------------------------------------------------------------------
374: //  Assignment 04
375: // --------------------------------------------------------------------------------------------------------
376: //   Perfom an insert into i_issue with parameters from the GET or POST.
377: //  The paramters should require 'body' and 'title' but allow for
378: //  defaults for "severity_id" and "issue_id" .  These should default
379: //  to '1' for the first ID in the set of ids.
380: //  For "issue_id" it should default to a new UUID if not specified.
381: //  Use `conn.QueryRow` do to the insert.  The query will require a "returning (id)".
382: //  YOu will need to return the inserted ID to the user.
383: // --------------------------------------------------------------------------------------------------------
384: 
385: //  HandleApiV1CreateIssue server to create a new issue in the i_issue table.
386: func HandleApiV1CreateIssue(www http.ResponseWriter, req *http.Request) {
387:     if req.Method == "GET" || req.Method == "POST" {
388:         fmt.Fprintf(www, `{"status":"TODO"}`)
389:     } else {
390:         LogInvalidMethodError(www, req)
391:     }
392: }
393: 
394: // --------------------------------------------------------------------------------------------------------
395: //  Assignment 04
396: // --------------------------------------------------------------------------------------------------------
397: //  Use a passed 'issue_id' to do a delete from i_issue table.
398: // --------------------------------------------------------------------------------------------------------
399: 
400: // HandleApiV1DeleteIssue server to delete an issue specified by the issue_id.
401: func HandleApiV1DeleteIssue(www http.ResponseWriter, req *http.Request) {
402:     fmt.Fprintf(www, `{"status":"TODO"}`)
403: }
404: 
405: // --------------------------------------------------------------------------------------------------------
406: //  Assignment 04
407: // --------------------------------------------------------------------------------------------------------
408: //  Take as input the issue_id, the title, the body and optionally a new severity_id and a new state_id
409: // and update the i_issue row specified by the issue_id.
410: // --------------------------------------------------------------------------------------------------------
411: 
412: //  HandleApiV1UpdateIssue server to update i_issue with title/body and optionally a new severity_id and
413: // state_id.  issue_id is a required parameter.
414: func HandleApiV1UpdateIssue(www http.ResponseWriter, req *http.Request) {
415:     fmt.Fprintf(www, `{"status":"TODO"}`)
416: }
417: 
418: // --------------------------------------------------------------------------------------------------------
419: //  Assignment 04
420: // --------------------------------------------------------------------------------------------------------
421: //  Given an issue_id and a new note, associate the note (insert) with the issue.
422: // --------------------------------------------------------------------------------------------------------
423: 
424: // HandleApiV1AddNoteToIssue server will insert a new note with a foreign key to an i_issue.
425: func HandleApiV1AddNoteToIssue(www http.ResponseWriter, req *http.Request) {
426:     fmt.Fprintf(www, `{"status":"TODO"}`)
427: }
428: 
429: // --------------------------------------------------------------------------------------------------------
430: //  Assignment 04
431: // --------------------------------------------------------------------------------------------------------
432: //  Given a note_id, delete that note from the associated i_issue.
433: // --------------------------------------------------------------------------------------------------------
434: 
435: //  HandleApiV1DeleteNote server will delete a note from an issue.
436: func HandleApiV1DeleteNote(www http.ResponseWriter, req *http.Request) {
437:     fmt.Fprintf(www, `{"status":"TODO"}`)
438: }
439: 
440: // --------------------------------------------------------------------------------------------------------
441: //  Assignment 04
442: // --------------------------------------------------------------------------------------------------------
443: //  Given an issue_id and a severity_id (requried parameters) update the issue with a new severity_id
444: // --------------------------------------------------------------------------------------------------------
445: 
446: // HandleApiV1UpdateSeverity server updates i_ssue with a new severity_id.
447: func HandleApiV1UpdateSeverity(www http.ResponseWriter, req *http.Request) {
448:     fmt.Fprintf(www, `{"status":"TODO"}`)
449: }
450: 
451: // HandleApiV1GetState server will select all rows from i_state and return them.
452: func HandleApiV1GetState(www http.ResponseWriter, req *http.Request) {
453:     if req.Method == "GET" {
454:         var v2 []*I_State
455:         stmt := "SELECT * FROM i_state"
456:         err := pgxscan.Select(ctx, conn, &v2, stmt)
457:         if err != nil {
458:             LogSQLError(www, req, stmt, err)
459:             return
460:         }
461: 
462:         SetJsonHdr(www, req)
463:         fmt.Fprintf(www, `{"status":"success","data":%s}`+"\n", SVarI(v2))
464:     } else {
465:         LogInvalidMethodError(www, req)
466:     }
467: }
468: 
469: // HandleApiV1GetSeverity server will select all rows form i_severity and return them.
470: func HandleApiV1GetSeverity(www http.ResponseWriter, req *http.Request) {
471:     if req.Method == "GET" {
472:         var v2 []*I_Severity
473:         stmt := "SELECT * FROM i_severity"
474:         err := pgxscan.Select(ctx, conn, &v2, stmt)
475:         if err != nil {
476:             LogSQLError(www, req, stmt, err)
477:             return
478:         }
479: 
480:         fmt.Fprintf(www, `%s`, StatusSuccess(SVarI(v2), www, req))
481:     } else {
482:         LogInvalidMethodError(www, req)
483:     }
484: }
485: 
486: // HandleApiV1GetNote server will select a single note if provided with a note_id
487: // or return all notes as alist for a specified issue_id
488: func HandleApiV1GetNote(www http.ResponseWriter, req *http.Request) {
489:     if req.Method == "GET" {
490:         note_id := GetParam("note_id", www, req)
491:         issue_id := GetParam("issue_id", www, req)
492:         if note_id == "" && issue_id == "" {
493:             LogParamError(www, req, "one of note_id, issue_id must be provided", "Missing Required Parameter")
494:         }
495: 
496:         var v2 []*I_Note
497:         if note_id == "" {
498:             stmt := "SELECT id, issue_id, seq, title, body FROM i_note issue_id = $1 order by seq"
499:             err := pgxscan.Select(ctx, conn, &v2, stmt, issue_id)
500:             if err != nil {
501:                 LogSQLError(www, req, stmt, err, issue_id)
502:                 return
503:             }
504:         } else {
505:             stmt := "SELECT id, issue_id, seq, title, body FROM i_note WHERE id = $1"
506:             err := pgxscan.Select(ctx, conn, &v2, stmt, note_id)
507:             if err != nil {
508:                 LogSQLError(www, req, stmt, err)
509:                 return
510:             }
511:         }
512: 
513:         fmt.Fprintf(www, `%s`, StatusSuccess(SVarI(v2), www, req))
514:     } else {
515:         LogInvalidMethodError(www, req)
516:     }
517: }
518: 
519: // --------------------------------------------------------------------------------------------------------
520: //  Assignment 04
521: // --------------------------------------------------------------------------------------------------------
522: //  Return a set of data from i_issue (or i_issue_st_sv would be more accurate) with all of the assocated
523: // notes for the issue.  This is the data that is used to paint the issue detail page.
524: //
525: // If you have an issue with:
526: //        title == "Ho - The Server is Broken"
527: //        body == "Yes this is true... The sever is down - not working. Getting error 52114"
528: //        severity_id,severity == 7, 'Severe - System down'
529: //        state_id,state == 2, 'Verified'
530: // And it has 2 notes:
531: //      1)
532: //          i_note.title == "I verified that it is true."
533: //          i_note.body == "Yes the server is down"
534: //      2)
535: //          i_note.title == "Restart Failed"
536: //          i_note.body == "Tried to just restart server - it failed."
537: //
538: // Then The JSON data returned would be (Note the order of the fields will be different):
539: //
540: // {
541: //   "status": "success"
542: //   "data": [
543: //        {
544: //          "id":  "<< Some UUID >>",
545: //          "title": "Ho - The Server is Broken",
546: //          "body": "Yes this is true... The sever is down - not working. Getting error 52114",
547: //          "state": "Verified",
548: //          "state_id": 2,
549: //          "severity": "Severe - System down"
550: //          "severity_id": 7,
551: //          "updated": "<< Some Timestamp data, might be null >>",
552: //          "created": "<< A created timestamp >>",
553: //            "n_rows_note": 2,
554: //            "note": [
555: //                {
556: //                    "id": "<< A Different UUID >>",
557: //                    "issue_id": "<< Some UUID (same as the i_issue UUID) >>",
558: //                    "seq": <<A Sequence Number, 55, 88 etc>>,
559: //                    "title": "I verified that it is true.",
560: //                    "body": "Yes the server is down"
561: //                },
562: //                {
563: //                    "id": "<< A 2nd Different UUID >>",
564: //                    "issue_id": "<< Some UUID (same as the i_issue UUID) >>",
565: //                    "seq": <<A Sequence Number, 95, 192 etc, Larger than above (Must be in increasing seq order>>
566: //                    "title": "Restart Failed",
567: //                    "body": "Tried to just restart server - it failed."
568: //                },
569: //          ]
570: //        }
571: //   ]
572: // }
573: //
574: // --------------------------------------------------------------------------------------------------------
575: 
576: // HandleApiV1GetIssueDetail serer returns an issue with it's associated notes.
577: func HandleApiV1GetIssueDetail(www http.ResponseWriter, req *http.Request) {
578:     fmt.Fprintf(www, `{"status":"TODO"}`)
579: }
580: 
581: // HandleApiV1UpdateState server updates i_issue with a new state_id.
582: func HandleApiV1UpdateState(www http.ResponseWriter, req *http.Request) {
583:     if req.Method == "GET" || req.Method == "POST" {
584:         issue_id := GetParam("issue_id", www, req)
585:         state_id := GetParam("state_id", www, req)
586:         RequiredParam(www, req, "issue_id", issue_id, "state_id", state_id)
587: 
588:         stmt := "update i_issue set state_id = $1 where id = $2"
589:         res, err := conn.Exec(ctx, stmt, state_id, issue_id)
590:         if err != nil {
591:             LogSQLError(www, req, stmt, err, state_id, issue_id)
592:             return
593:         }
594:         nr := res.RowsAffected()
595:         if nr != 1 {
596:             LogSQLError(www, req, stmt, fmt.Errorf("Invalid number of rows %d - should be 1", nr), issue_id)
597:             return
598:         }
599: 
600:         SetJsonHdr(www, req)
601:         fmt.Fprintf(www, `{"status":"success"}`+"\n")
602:     } else {
603:         LogInvalidMethodError(www, req)
604:     }
605: }
