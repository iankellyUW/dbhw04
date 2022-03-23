package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/georgysavva/scany/pgxscan"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/pschlump/MiscLib"
	"github.com/pschlump/filelib"
	"go.uber.org/zap"
)

// These are the values pulled in from ./cfg.json file.
type GlobalConfig struct {
	StaticPath string `json:"static_files"`
	Host       string
	Port       string
	DbFlags    []string `json:"db_flags"`
}

var gCfg GlobalConfig
var DbOn map[string]bool = make(map[string]bool)
var sugar *zap.SugaredLogger

// Database Context and Connection
var conn *pgxpool.Pool
var ctx context.Context

func main() {

	// --------------------------------------------------------------------------------------
	// Read global config
	// --------------------------------------------------------------------------------------
	ReadJson("cfg.json", &gCfg)
	if len(gCfg.DbFlags) > 0 {
		for _, x := range gCfg.DbFlags {
			DbOn[x] = true
		}
	}

	if DbOn["dump-global-config"] {
		fmt.Printf("Global Config:%s\n", SVarI(gCfg))
	}

	// --------------------------------------------------------------------------------------
	// Setup Logging
	// --------------------------------------------------------------------------------------
	os.MkdirAll("./log", 0755)
	logFp, err := filelib.Fopen("./log/log.out", "a")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to open ./log/log.out for loging/append, error:%s\n", err)
		os.Exit(1)
	}
	sugar = LogInit(DbOn["debug-log"], logFp)

	// --------------------------------------------------------------------------------------
	// Connect to database - if we get to the defer then we have successfuly connected.
	// --------------------------------------------------------------------------------------
	ConnectToDb()
	defer DisConnectToDb()

	// --------------------------------------------------------------------------------------
	// Routes
	// --------------------------------------------------------------------------------------
	mux := http.NewServeMux()
	mux.Handle("/api/v1/hello", http.HandlerFunc(HandleHelloWorld))
	mux.Handle("/api/v1/global-data.js", http.HandlerFunc(HandleApiV1GlobalData))
	mux.Handle("/api/v1/status", http.HandlerFunc(HandleStatus))
	mux.Handle("/status", http.HandlerFunc(HandleStatus))
	mux.Handle("/api/v1/db-version", http.HandlerFunc(HandleApiV1DbVersion))
	mux.Handle("/api/v1/get-config", http.HandlerFunc(HandleApiV1GetConfig))
	mux.Handle("/api/v1/search-keyword", http.HandlerFunc(HandleApiV1SearchKeyword))
	mux.Handle("/api/v1/issue-list", http.HandlerFunc(HandleApiV1IssueList))
	mux.Handle("/api/v1/create-issue", http.HandlerFunc(HandleApiV1CreateIssue))
	mux.Handle("/api/v1/delete-issue", http.HandlerFunc(HandleApiV1DeleteIssue))
	mux.Handle("/api/v1/get-severity", http.HandlerFunc(HandleApiV1GetSeverity))
	mux.Handle("/api/v1/get-state", http.HandlerFunc(HandleApiV1GetState))
	mux.Handle("/api/v1/add-note-to-issue", http.HandlerFunc(HandleApiV1AddNoteToIssue))
	mux.Handle("/api/v1/get-note", http.HandlerFunc(HandleApiV1GetNote))
	mux.Handle("/api/v1/update-issue", http.HandlerFunc(HandleApiV1UpdateIssue))
	mux.Handle("/api/v1/delete-note", http.HandlerFunc(HandleApiV1DeleteNote))
	mux.Handle("/api/v1/update-severity", http.HandlerFunc(HandleApiV1UpdateSeverity))
	mux.Handle("/api/v1/update-state", http.HandlerFunc(HandleApiV1UpdateState))
	mux.Handle("/api/v1/get-issue-detail", http.HandlerFunc(HandleApiV1GetIssueDetail))

	// --------------------------------------------------------------------------------------
	// server static files.
	// --------------------------------------------------------------------------------------
	{
		Dir := gCfg.StaticPath
		if DbOn["print.static.path"] {
			fmt.Printf("%sPath: %s%s\n", MiscLib.ColorYellow, Dir, MiscLib.ColorReset)
		}
		fs := http.FileServer(http.Dir(Dir))
		fx := func(www http.ResponseWriter, req *http.Request) {
			www.Header().Set("Cache-Control", "public, max-age=1")
			fs.ServeHTTP(www, req)
		}
		mux.Handle("/", http.HandlerFunc(fx))
	}

	// --------------------------------------------------------------------------------------
	// start server.
	// --------------------------------------------------------------------------------------
	svr := http.Server{
		Addr:    gCfg.Host + ":" + gCfg.Port,
		Handler: ApacheLogger(CORSMiddleware(mux)),
	}
	log.Fatal(svr.ListenAndServe())
}

// ----------------------------------------------------------- Structs for SQL  -----------------------------------------------------------------

/*
CREATE table i_note (
	id 					uuid default uuid_generate_v4() not null primary key,
	issue_id 			uuid not null,
	seq 				serial not null,
	title 				text not null,
	body 				text not null,
	words				tsvector,
	updated 			timestamp,
	created 			timestamp default current_timestamp not null
);
*/
type I_Note struct {
	Id       string `json:"id"`
	Issue_id string `json:"issue_id"`
	Seq      int    `json":"seq"`
	Title    string `json:"title"`
	Body     string `json:"body"`
}

// "github.com/jackc/pgtype"
// See: https://github.com/georgysavva/scany/blob/master/pgxscan/pgxscan_test.go

//CREATE table if not exists i_state (
//	id serial not null primary key,
//	state text not null
//);
type I_State struct {
	Id    int    `json:"id"`
	State string `json:"state"`
}

//CREATE table if not exists i_severity (
//	id serial not null primary key,
//	severity text not null
//);
type I_Severity struct {
	Id       int    `json:"id"`
	Severity string `json:"severity"`
}

/*
CREATE OR REPLACE VIEW i_issue_st_sv AS
	select
		  t1.id
		, t1.title
		, t1.body
		, t2.state
		, t1.state_id
		, t3.severity
		, t1.severity_id
		, t1.updated
		, t1.created
		, t1.words
	from i_issue as t1
		join i_state as t2 on ( t2.id = t1.state_id )
		join i_severity as t3 on ( t3.id = t1.severity_id )
	where t2.state != 'Deleted'
	order by t1.severity_id desc, t1.updated desc, t1.created desc
;
*/
type I_Issue_St_Sv struct {
	Id          string     `json:"id"`
	Title       string     `json:"title"`
	Body        string     `json:"body"`
	State       string     `json:"state"`
	State_id    int        `json:"state_id"`
	Severity    string     `json:"severity"`
	Severity_id int        `json:"severity_id"`
	Updated     *time.Time `json:"updated"`
	Created     *time.Time `json:"created"`
	Words       string
}

type I_Issue_And_Notes struct {
	Id          string     `json:"id"`
	Title       string     `json:"title"`
	Body        string     `json:"body"`
	State       string     `json:"state"`
	State_id    int        `json:"state_id"`
	Severity    string     `json:"severity"`
	Severity_id int        `json:"severity_id"`
	Updated     *time.Time `json:"updated"`
	Created     *time.Time `json:"created"`
	N_Notes     int        `json:"n_rows_note"`
	Notes       []*I_Note  `json:"note"`
}

type I_Config struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

type AString struct {
	Val string `json:"val"`
}

// ----------------------------------------------------------- Handlers -----------------------------------------------------------------

// HandleHelloWorld server to respond with "Hello World\n"
func HandleHelloWorld(www http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(www, "Hello World\n")
}

// HandleStatus server to respond with a working message if up.
func HandleStatus(www http.ResponseWriter, req *http.Request) {
	www.WriteHeader(http.StatusOK) // 200
	var v []*AString
	stmt := "SELECT 'Database-OK' as \"val\""
	err := pgxscan.Select(ctx, conn, &v, stmt)
	if err != nil {
		LogSQLError(www, req, stmt, err)
		return
	}
	SetJsonHdr(www, req)
	if len(v) > 0 {
		fmt.Fprintf(www, `{"status":"success", "database":"ok", "req":%s}`, SVarI(req))
	} else {
		fmt.Fprintf(www, `{"status":"error", "database":"no-response","req":%s}`, SVarI(req))
	}
	return
}

// HandleApiV1GlobalData server to respond with a JavaScript file that has i_state and i_severity data in it as code.
func HandleApiV1GlobalData(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" {
		// EnableCoors(www, req)
		var v1 []*I_State
		stmt := "SELECT * from i_state"
		err := pgxscan.Select(ctx, conn, &v1, stmt)
		if err != nil {
			LogSQLError(www, req, stmt, err)
			return
		}
		s1 := SVarI(v1)

		var v2 []*I_Severity
		err = pgxscan.Select(ctx, conn, &v2, "SELECT * from i_severity")
		if err != nil {
			LogSQLError(www, req, stmt, err)
			return
		}
		s2 := SVarI(v2)

		www.Header().Set("Content-Type", "text/javascript;charset=UTF-8")
		fmt.Fprintf(www, `
var g_state = %s;

var g_severity = %s;
`, s1, s2)
	} else {
		LogInvalidMethodError(www, req)
	}
}

// HandleApiV1GetConfig server to respoind with return data from i_config
func HandleApiV1GetConfig(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" {
		var v1 []*I_Config
		stmt := "SELECT * from i_config"
		err := pgxscan.Select(ctx, conn, &v1, stmt)
		if err != nil {
			LogSQLError(www, req, stmt, err)
			return
		}
		fmt.Fprintf(www, "%s", StatusSuccess(SVarI(v1), www, req))
	} else {
		LogInvalidMethodError(www, req)
	}
}

// HandleApiV1DbVersion server to respoind with the version of the tabase as text.
// This is useful to verify that the database is up and the Go code is connecting
// to it.
func HandleApiV1DbVersion(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" {
		var v []*AString
		stmt := "SELECT version() as \"val\""
		err := pgxscan.Select(ctx, conn, &v, stmt)
		if err != nil {
			LogSQLError(www, req, stmt, err)
			return
		}

		SetJsonHdr(www, req)
		if len(v) > 0 {
			fmt.Fprintf(www, "%s\n", v[0].Val)
		} else {
			fmt.Fprintf(www, "{\"error\":\"Unable to get version information\"}\n")
		}
	} else {
		LogInvalidMethodError(www, req)
	}
}

// HandleApiV1SearchKeyword server to perform a keyword search on i_issue.title and i_issue.body
// This uses a to_tsquery in the configured language (default english).   The data should be from
// the view i_issue_st_sv that joins i_issue with i_state and i_severity.
func HandleApiV1SearchKeyword(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" || req.Method == "POST" {
		kw := GetParam("kw", www, req)
		if RequiredParam(www, req, "kw", kw) != nil {
			return
		}

		// Get the Language
		var v1 []*I_Config
		stmt := "SELECT Name, Value from i_config where name = 'language'"
		err := pgxscan.Select(ctx, conn, &v1, stmt)
		if err != nil {
			LogSQLError(www, req, stmt, err)
			return
		}
		lang := "english" // default to english
		if len(v1) >= 1 {
			lang = v1[0].Value
		}

		var v2 []*I_Issue_St_Sv
		stmt = "SELECT * FROM i_issue_st_sv where words @@ to_tsquery($1::regconfig,$2)"
		err = pgxscan.Select(ctx, conn, &v2, stmt, lang, kw)
		if err != nil {
			LogSQLError(www, req, stmt, err, lang, kw)
			return
		}

		fmt.Fprintf(www, "%s", StatusSuccess(SVarI(v2), www, req))
	} else {
		LogInvalidMethodError(www, req)
	}
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//    Use `pgxscan.Select ( "SELECT * FROM i_issue_st_sv", {})`
//   to select back the set of issues  in the database
//   that are not `Deleted`.   Create the view i_issue_st_sv
//   to join from i_issue to i_state and i_severity so that
//   both the state_id and the state are returned (this is the i_issue_st_sv view).  Sort the
//   data into descending severity_id, and descending creation
//   and update  dates.   The view i_issue_st_sv should be
//   added to your data model that you turn in.
// --------------------------------------------------------------------------------------------------------

// HandleApiV1IssueList server to respond with the data from the i_issue_st_sv view (i_issue).
func HandleApiV1IssueList(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" {
		fmt.Fprintf(www, `{"status":"TODO"}`)
	} else {
		LogInvalidMethodError(www, req)
	}
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//   Perfom an insert into i_issue with parameters from the GET or POST.
//  The paramters should require 'body' and 'title' but allow for
//  defaults for "severity_id" and "issue_id" .  These should default
//  to '1' for the first ID in the set of ids.
//  For "issue_id" it should default to a new UUID if not specified.
//  Use `conn.QueryRow` do to the insert.  The query will require a "returning (id)".
//  YOu will need to return the inserted ID to the user.
// --------------------------------------------------------------------------------------------------------

//  HandleApiV1CreateIssue server to create a new issue in the i_issue table.
func HandleApiV1CreateIssue(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" || req.Method == "POST" {
		fmt.Fprintf(www, `{"status":"TODO"}`)
	} else {
		LogInvalidMethodError(www, req)
	}
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//  Use a passed 'issue_id' to do a delete from i_issue table.
// --------------------------------------------------------------------------------------------------------

// HandleApiV1DeleteIssue server to delete an issue specified by the issue_id.
func HandleApiV1DeleteIssue(www http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(www, `{"status":"TODO"}`)
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//  Take as input the issue_id, the title, the body and optionally a new severity_id and a new state_id
// and update the i_issue row specified by the issue_id.
// --------------------------------------------------------------------------------------------------------

//  HandleApiV1UpdateIssue server to update i_issue with title/body and optionally a new severity_id and
// state_id.  issue_id is a required parameter.
func HandleApiV1UpdateIssue(www http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(www, `{"status":"TODO"}`)
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//  Given an issue_id and a new note, associate the note (insert) with the issue.
// --------------------------------------------------------------------------------------------------------

// HandleApiV1AddNoteToIssue server will insert a new note with a foreign key to an i_issue.
func HandleApiV1AddNoteToIssue(www http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(www, `{"status":"TODO"}`)
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//  Given a note_id, delete that note from the associated i_issue.
// --------------------------------------------------------------------------------------------------------

//  HandleApiV1DeleteNote server will delete a note from an issue.
func HandleApiV1DeleteNote(www http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(www, `{"status":"TODO"}`)
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//  Given an issue_id and a severity_id (requried parameters) update the issue with a new severity_id
// --------------------------------------------------------------------------------------------------------

// HandleApiV1UpdateSeverity server updates i_ssue with a new severity_id.
func HandleApiV1UpdateSeverity(www http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(www, `{"status":"TODO"}`)
}

// HandleApiV1GetState server will select all rows from i_state and return them.
func HandleApiV1GetState(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" {
		var v2 []*I_State
		stmt := "SELECT * FROM i_state"
		err := pgxscan.Select(ctx, conn, &v2, stmt)
		if err != nil {
			LogSQLError(www, req, stmt, err)
			return
		}

		SetJsonHdr(www, req)
		fmt.Fprintf(www, `{"status":"success","data":%s}`+"\n", SVarI(v2))
	} else {
		LogInvalidMethodError(www, req)
	}
}

// HandleApiV1GetSeverity server will select all rows form i_severity and return them.
func HandleApiV1GetSeverity(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" {
		var v2 []*I_Severity
		stmt := "SELECT * FROM i_severity"
		err := pgxscan.Select(ctx, conn, &v2, stmt)
		if err != nil {
			LogSQLError(www, req, stmt, err)
			return
		}

		fmt.Fprintf(www, `%s`, StatusSuccess(SVarI(v2), www, req))
	} else {
		LogInvalidMethodError(www, req)
	}
}

// HandleApiV1GetNote server will select a single note if provided with a note_id
// or return all notes as alist for a specified issue_id
func HandleApiV1GetNote(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" {
		note_id := GetParam("note_id", www, req)
		issue_id := GetParam("issue_id", www, req)
		if note_id == "" && issue_id == "" {
			LogParamError(www, req, "one of note_id, issue_id must be provided", "Missing Required Parameter")
		}

		var v2 []*I_Note
		if note_id == "" {
			stmt := "SELECT id, issue_id, seq, title, body FROM i_note issue_id = $1 order by seq"
			err := pgxscan.Select(ctx, conn, &v2, stmt, issue_id)
			if err != nil {
				LogSQLError(www, req, stmt, err, issue_id)
				return
			}
		} else {
			stmt := "SELECT id, issue_id, seq, title, body FROM i_note WHERE id = $1"
			err := pgxscan.Select(ctx, conn, &v2, stmt, note_id)
			if err != nil {
				LogSQLError(www, req, stmt, err)
				return
			}
		}

		fmt.Fprintf(www, `%s`, StatusSuccess(SVarI(v2), www, req))
	} else {
		LogInvalidMethodError(www, req)
	}
}

// --------------------------------------------------------------------------------------------------------
//  Assignment 04
// --------------------------------------------------------------------------------------------------------
//  Return a set of data from i_issue (or i_issue_st_sv would be more accurate) with all of the assocated
// notes for the issue.  This is the data that is used to paint the issue detail page.
//
// If you have an issue with:
//		title == "Ho - The Server is Broken"
//		body == "Yes this is true... The sever is down - not working. Getting error 52114"
//		severity_id,severity == 7, 'Severe - System down'
//		state_id,state == 2, 'Verified'
// And it has 2 notes:
//      1)
//		  i_note.title == "I verified that it is true."
//		  i_note.body == "Yes the server is down"
//      2)
//		  i_note.title == "Restart Failed"
//		  i_note.body == "Tried to just restart server - it failed."
//
// Then The JSON data returned would be (Note the order of the fields will be different):
//
// {
//   "status": "success"
//   "data": [
//		{
//          "id":  "<< Some UUID >>",
//          "title": "Ho - The Server is Broken",
//          "body": "Yes this is true... The sever is down - not working. Getting error 52114",
//          "state": "Verified",
//          "state_id": 2,
//          "severity": "Severe - System down"
//          "severity_id": 7,
//          "updated": "<< Some Timestamp data, might be null >>",
//          "created": "<< A created timestamp >>",
//			"n_rows_note": 2,
//	        "note": [
//				{
//					"id": "<< A Different UUID >>",
//					"issue_id": "<< Some UUID (same as the i_issue UUID) >>",
//					"seq": <<A Sequence Number, 55, 88 etc>>,
//					"title": "I verified that it is true.",
//					"body": "Yes the server is down"
//				},
//				{
//					"id": "<< A 2nd Different UUID >>",
//					"issue_id": "<< Some UUID (same as the i_issue UUID) >>",
//					"seq": <<A Sequence Number, 95, 192 etc, Larger than above (Must be in increasing seq order>>
//					"title": "Restart Failed",
//					"body": "Tried to just restart server - it failed."
//				},
//          ]
//		}
//   ]
// }
//
// --------------------------------------------------------------------------------------------------------

// HandleApiV1GetIssueDetail serer returns an issue with it's associated notes.
func HandleApiV1GetIssueDetail(www http.ResponseWriter, req *http.Request) {
	fmt.Fprintf(www, `{"status":"TODO"}`)
}

// HandleApiV1UpdateState server updates i_issue with a new state_id.
func HandleApiV1UpdateState(www http.ResponseWriter, req *http.Request) {
	if req.Method == "GET" || req.Method == "POST" {
		issue_id := GetParam("issue_id", www, req)
		state_id := GetParam("state_id", www, req)
		RequiredParam(www, req, "issue_id", issue_id, "state_id", state_id)

		stmt := "update i_issue set state_id = $1 where id = $2"
		res, err := conn.Exec(ctx, stmt, state_id, issue_id)
		if err != nil {
			LogSQLError(www, req, stmt, err, state_id, issue_id)
			return
		}
		nr := res.RowsAffected()
		if nr != 1 {
			LogSQLError(www, req, stmt, fmt.Errorf("Invalid number of rows %d - should be 1", nr), issue_id)
			return
		}

		SetJsonHdr(www, req)
		fmt.Fprintf(www, `{"status":"success"}`+"\n")
	} else {
		LogInvalidMethodError(www, req)
	}
}
