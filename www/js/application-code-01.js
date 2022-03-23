
window.g_data = {};
window.g_msg = [];

function tss(tmpl, ns, fx) {
	if ( typeof fx == "undefined" ) { fx = {} };
	var p1 = tmpl.replace(/%{([A-Za-z0-9_|.,]*)%}/g, function(j, t) {
			var pl;
			var s = "";
			var a = t.split("|");
			for ( var i = 0; i < a.length; i++ ) {
				pl = a[i].split(",");
				if ( typeof fx [ pl[0] ] == "function" ) {
					var f = fx[ pl[0] ];
					s = f(s,ns,pl);									// Now call each function as a pass thru-filter
				} else if ( typeof ns [ pl[0] ] == "string" || typeof ns [ pl[0] ] == "number" ) {
					s = ns[ pl[0] ];
				} else {
					s = "";
				}
			}
			return s;
		});
	return p1;
};

function renderError ( title, msg, data ) {
	$("#foo").show();
	$("#foo_class").removeClass("bg-success").removeClass("bg-danger").addClass("bg-danger");
	$("#foo_title").html(title);
	$("#foo_msg").html(msg);
	window.g_msg.push ( { "type": "error", "title": title, "msg": msg } );
}


function renderMessage ( title, msg, data ) {
	$("#foo").show();
	$("#foo_class").removeClass("bg-success").removeClass("bg-danger").addClass("bg-success");
	// $("#foo_class").removeClass("bg-dnager").addClass("bg-success");
	$("#foo_title").html(title);
	$("#foo_msg").html(msg);
	window.g_msg.push ( { "type": "message/success", "title": title, "msg": msg } );
}

function renderSuccess ( title, msg, data ) {
	renderMessage( title, msg, data );
}

function renderClearMessage() {
	$("#foo").hide();
}
var curTimeout = null;
function render5SecClearMessage() {
	if ( curTimeout ) {
		clearTimeout(curTimeout);
		curTimeout = null;
	}
	curTimeout = setTimeout(function() {
		$("#foo").hide();
	}, 5000);
}


$("#help").click(renderHelp);

$("#getStatus").click(function(event){
	if ( event && event.preventDefault && typeof event.preventDefault == "function") { event.preventDefault(); }
	$.ajax({
		type: 'GET',
		url: "/api/v1/status",
		data: {},
		success: function (data) {
			$("#body").html( "<pre>"+JSON.stringify(data)+"</pre>" );
		},
		error: function(resp) {
			$("#output").text( "Error!"+JSON.stringify(resp) );
		}
	});
});

function renderSelect ( id, curval, data, xid, classname ) {
	var rv = [
		`<select class="${classname}" data-id="${xid}" id="${id}" name="${id}">\n`
	];
	for ( var ii = 0, mx = data.length; ii < mx; ii++ ) {
		if ( data[ii].value === curval ) {
			rv.push ( `<option value="${data[ii].value}" selected>${data[ii].name}</option>\n` );
		} else {
			rv.push ( `<option value="${data[ii].value}">${data[ii].name}</option>\n` );
		}
	}
	rv.push ( `</select>\n` );
	return rv.join("");
};

// -----------------------------------------------------------------------------------------------------------------------
// Xyzzy - new for issue
//						<button type="button" class="btn btn-primary bind-click" data-click="addNewIssue">New Issue</button>
//						<button type="button" class="btn btn-primary bind-click" data-click="showClosedIssues">Show Closed Issues</button>
//						<button type="button" class="btn btn-primary bind-click" data-click="refreshIssueList">Refresh List</button>
// Xyzzy - new for confirm delete issue
//	window.g_data = {};
//		Also uses issue_id
//						<div> Title: {{issue_title}} </div>
//						<div> Body: {{issue_body}} </div>
//						<button type="button" class="btn btn-primary bind-click" data-click="confirmDeleteIssue">Confirm</button>
//						<a class="btn btn-primary bind-click" data-click="cancelDeleteIssue">Cancel</a>
// ./mt/CreateIssue.html 
//						<button type="button" class="btn btn-primary bind-click" data-click="saveNewIssue">Save Issue</button>
//						<a class="btn btn-primary bind-click" data-click="cancelReturnToDashboard">Cancel</a>

function addNewIssue() {
	window.g_data["issue_id"] = "";
	window.g_data["issue_title"] = "";
	window.g_data["issue_body"] = "";
	window.g_data["crud_action"] = "create";
	renderCreateIssue();
}
function refreshIssueList() {
	window.g_data = {};
	renderDashboard();
}

function confirmDeleteIssue(event) {
	if ( event && event.preventDefault && typeof event.preventDefault == "function") { event.preventDefault(); }
	var issue_id = window.g_data["issue_id"];
	// console.log ( "issue_id =", issue_id );
	// window.g_data["issue_id"] = issue_id;
	var url = "/api/v1/delete-issue";
	var getdata = {
		  "issue_id"		: issue_id
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "success AJAX delete issue", data );
			renderSuccess ( "Issue Deleted", "" );
			render5SecClearMessage ( );
			window.g_data = {};
			renderDashboard();
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			// $("#output-dbg").text( "Error!"+JSON.stringify(resp) );
			// alert("got error status="+resp.status+" "+resp.statusText);
			var msg = resp.statusText;
			renderError ( "Failed to Delete Issue", msg );
			render5SecClearMessage ( );
		}
	});
}
function cancelDeleteIssue(event) {
	if ( event && event.preventDefault && typeof event.preventDefault == "function") { event.preventDefault(); }
	window.g_data = {};
	renderDashboard();
}
function cancelReturnToDashboard() {
	window.g_data = {};
	renderDashboard();
}

function changeIssueSeverity( issue_id, severity_id ) {
	// var issue_id = $(this).data("issue_id");
	// var severity_id = $("#severity-"+issue_id).val();
	var url = "/api/v1/update-severity";
	var getdata = {
		  "issue_id"		: issue_id
		, "severity_id"		: severity_id
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "Success update severity", data );
			renderSuccess ( "Severity Updated", "" );
			render5SecClearMessage ( );
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "Failed to Update Severity", msg );
			render5SecClearMessage ( );
		}
	});
}
function changeIssueState( issue_id, state_id ) {
	// var issue_id = $(this).data("issue_id");
	// var state_id = $("#state-"+issue_id).val();
	var url = "/api/v1/update-state";
	var getdata = {
		  "issue_id"		: issue_id
		, "state_id"		: state_id
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "Success update state", data );
			renderSuccess ( "State Updated", "" );
			render5SecClearMessage ( );
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "Failed to Update State", msg );
			render5SecClearMessage ( );
		}
	});
}
function deleteIssue(event,issue_id) {
	console.log ( "in deleteIssue: issue_id = ", issue_id );
	if ( event && event.preventDefault && typeof event.preventDefault == "function") { event.preventDefault(); }
	window.g_data["issue_id"] = issue_id;
	var n = getIssue(issue_id);
	window.g_data["issue_title"] = n["title"];
	window.g_data["issue_body"] = n["body"];
	window.g_data["crud_action"] = "delete";
	renderIssueConfirmDelete();
}
function editIssue(event,issue_id) {
	console.log ( "in editIssue: issue_id = ", issue_id );
	if ( event && event.preventDefault && typeof event.preventDefault == "function") { event.preventDefault(); }
	window.g_data["issue_id"] = issue_id;
	var n = getIssue ( issue_id );
	window.g_data["issue_title"] = n["title"];
	window.g_data["issue_body"] = n["body"];
	window.g_data["crud_action"] = "update";
	renderUpdateIssue(event,issue_id,"create");
}



function preRenderDashboard () {
	console.log ( "pre - Dashboard" );
}
function postRenderDashboard () {
	window.g_data = {};
	console.log ( "post - Dashboard" );

	var url = "/api/v1/issue-list";
	var getdata = {
		  "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "success AJAX", data );
			// $("#output-dbg").text( JSON.stringify(data, null, 4) );

			function ActionFunc_severity ( idCol, fullRow, fullTableData, rowNum, colNum, colName ) {
				var issue_id = fullRow["id"];
				return "<td>" + renderSelect ( "severity-"+issue_id, fullRow["severity_id"], severity_select_data, issue_id, "target-severity" ) + "</td>";
			};
			function ActionFunc_state ( idCol, fullRow, fullTableData, rowNum, colNum, colName ) {
				var issue_id = fullRow["id"];
				return "<td>" + renderSelect ( "state-"+issue_id, fullRow["state_id"], state_select_data, issue_id, "target-state" ) + "</td>";
			};

			var x_hdrCfg = {
				ColNames: 	[
					{ Name:"Title"},
					{ Name:"Severity"},
					{ Name:"State" },
					{ Name:"Action" }
				],
			};
			var x_rowCfg = {
				cols: [
						{ Name: "title", rowTmpl: "<a href=\"#\" onclick='editIssue(event,\"%{id%}\")' class=\"title-large\">%{title%}</a>" },
						{ Name: "severity_id", fx: ActionFunc_severity },
						{ Name: "state_id", fx: ActionFunc_state },
						{ Name: "id", rowTmpl: `<a href="#" class="btn btn-primary" onclick='editIssue(event,"%{id%}")'> <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-pencil-fill" viewBox="0 0 16 16"> <path d="M12.854.146a.5.5 0 0 0-.707 0L10.5 1.793 14.207 5.5l1.647-1.646a.5.5 0 0 0 0-.708l-3-3zm.646 6.061L9.793 2.5 3.293 9H3.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.207l6.5-6.5zm-7.468 7.468A.5.5 0 0 1 6 13.5V13h-.5a.5.5 0 0 1-.5-.5V12h-.5a.5.5 0 0 1-.5-.5V11h-.5a.5.5 0 0 1-.5-.5V10h-.5a.499.499 0 0 1-.175-.032l-.179.178a.5.5 0 0 0-.11.168l-2 5a.5.5 0 0 0 .65.65l5-2a.5.5 0 0 0 .168-.11l.178-.178z"/> </svg> </a> <a href="#" class="btn btn-primary" onclick='deleteIssue(event,"%{id%}")'> <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-trash" viewBox="0 0 16 16"> <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/> <path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4L4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/> </svg> </a>` },
				]
			};

			renderTableTo ( "#form01", data.data, x_hdrCfg, x_rowCfg );
			$('.target-severity').change( function() {
				var issue_id = $(this).data("id");
				$(this).find(":selected").each(function () {
					var severity_id = $(this).val();
					console.log( "severity change:", severity_id, "issue_id=", issue_id );
					changeIssueSeverity( issue_id, severity_id );
				});
			});
			$('.target-state').change( function() {
				var issue_id = $(this).data("id");
				$(this).find(":selected").each(function () {
					var state_id = $(this).val();
					console.log( "state change:", state_id, "issue_id=", issue_id );
					changeIssueState( issue_id, state_id );
				});
			});

			for ( var ii = 0, mx = data.data.length; ii < mx; ii++ ) {			
				saveIssue ( 
					data.data[ii]["id"], // issue_id
					data.data[ii]["title"],
					data.data[ii]["body"],
					data.data[ii]["state"],
					data.data[ii]["severity"]
				);
			}
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "Xyzzy-title:doc-index.js:79", msg );
			render5SecClearMessage ( );
		}
	});
}

function preRenderKeywordDashboard () {
	console.log ( "pre - KeywordDashboard" );
}
function postRenderKeywordDashboard () {
	// window.g_data = {};
	console.log ( "post - KeywordDashboard" );

	var url = "/api/v1/search-keyword"
	var getdata = {
		  "kw"              : window.g_data["kw"]
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "success AJAX", data );
			// $("#output-dbg").text( JSON.stringify(data, null, 4) );

			function ActionFunc_severity ( idCol, fullRow, fullTableData, rowNum, colNum, colName ) {
				var issue_id = fullRow["id"];
				return "<td>" + renderSelect ( "severity-"+issue_id, fullRow["severity_id"], severity_select_data, issue_id, "target-severity" ) + "</td>";
			};
			function ActionFunc_state ( idCol, fullRow, fullTableData, rowNum, colNum, colName ) {
				var issue_id = fullRow["id"];
				return "<td>" + renderSelect ( "state-"+issue_id, fullRow["state_id"], state_select_data, issue_id, "target-state" ) + "</td>";
			};

			var x_hdrCfg = {
				ColNames: 	[
					{ Name:"Title"},
					{ Name:"Severity"},
					{ Name:"State" },
					{ Name:"Action" }
				],
			};
			var x_rowCfg = {
				cols: [
						{ Name: "title", rowTmpl: "<a href=\"#\" onclick='editIssue(event,\"%{id%}\")' class=\"title-large\">%{title%}</a>" },
						{ Name: "severity_id", fx: ActionFunc_severity },
						{ Name: "state_id", fx: ActionFunc_state },
						{ Name: "id", rowTmpl: `<a href="#" class="btn btn-primary" onclick='editIssue(event,"%{id%}")'> <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-pencil-fill" viewBox="0 0 16 16"> <path d="M12.854.146a.5.5 0 0 0-.707 0L10.5 1.793 14.207 5.5l1.647-1.646a.5.5 0 0 0 0-.708l-3-3zm.646 6.061L9.793 2.5 3.293 9H3.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.5h.5a.5.5 0 0 1 .5.5v.207l6.5-6.5zm-7.468 7.468A.5.5 0 0 1 6 13.5V13h-.5a.5.5 0 0 1-.5-.5V12h-.5a.5.5 0 0 1-.5-.5V11h-.5a.5.5 0 0 1-.5-.5V10h-.5a.499.499 0 0 1-.175-.032l-.179.178a.5.5 0 0 0-.11.168l-2 5a.5.5 0 0 0 .65.65l5-2a.5.5 0 0 0 .168-.11l.178-.178z"/> </svg> </a> <a href="#" class="btn btn-primary" onclick='deleteIssue(event,"%{id%}")'> <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-trash" viewBox="0 0 16 16"> <path d="M5.5 5.5A.5.5 0 0 1 6 6v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm2.5 0a.5.5 0 0 1 .5.5v6a.5.5 0 0 1-1 0V6a.5.5 0 0 1 .5-.5zm3 .5a.5.5 0 0 0-1 0v6a.5.5 0 0 0 1 0V6z"/> <path fill-rule="evenodd" d="M14.5 3a1 1 0 0 1-1 1H13v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V4h-.5a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1H6a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1h3.5a1 1 0 0 1 1 1v1zM4.118 4L4 4.059V13a1 1 0 0 0 1 1h6a1 1 0 0 0 1-1V4.059L11.882 4H4.118zM2.5 3V2h11v1h-11z"/> </svg> </a>` },
				]
			};

			renderTableTo ( "#form01", data.data, x_hdrCfg, x_rowCfg );
			$('.target-severity').change( function() {
				var issue_id = $(this).data("id");
				$(this).find(":selected").each(function () {
					var severity_id = $(this).val();
					console.log( "severity change:", severity_id, "issue_id=", issue_id );
					changeIssueSeverity( issue_id, severity_id );
				});
			});
			$('.target-state').change( function() {
				var issue_id = $(this).data("id");
				$(this).find(":selected").each(function () {
					var state_id = $(this).val();
					console.log( "state change:", state_id, "issue_id=", issue_id );
					changeIssueState( issue_id, state_id );
				});
			});

			if ( data && data.data && data.data.length ) {
				for ( var ii = 0, mx = data.data.length; ii < mx; ii++ ) {			
					saveIssue ( 
						data.data[ii]["id"], // issue_id
						data.data[ii]["title"],
						data.data[ii]["body"],
						data.data[ii]["state"],
						data.data[ii]["severity"]
					);
				}
			}
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "xyzzy-title:doc-index.js:79", msg );
			render5SecClearMessage ( );
		}
	});
}



function submitKeywordSearch(event) {
	if ( event && event.preventDefault && typeof event.preventDefault == "function") { event.preventDefault(); }
	window.g_data["kw"] = $("#kw").val();
	renderKeywordDashboard();
}


// -----------------------------------------------------------------------------------------------------------------------
// Update Issue Code
// -----------------------------------------------------------------------------------------------------------------------

function preRenderUpdateIssue () {
	console.log ( "pre UpdateIssue" );
}
function postRenderUpdateIssue () {
	console.log ( "post UpdateIssue" );
	var issue_id = window.g_data["issue_id"];

	// Populate the 2 dropdowns.
	var n = getIssue ( issue_id );

	var s = renderSelect ( "state_id", n["state_id"], state_select_data, issue_id, "css-class-create-state" );
	$("#paint-state").html(s);

	var s = renderSelect ( "severity_id", n["severity_id"], severity_select_data, issue_id, "css-class-create-severity" );
	$("#paint-severity").html(s);

	postAddNotesToIssue ( issue_id );
}


function updateIssue(event) {
	console.log ( "in updateIssue", window.g_data );
	if ( event && event.preventDefault && typeof event.preventDefault == "function") { event.preventDefault(); }
	var issue_id = window.g_data["issue_id"];
	var state_id = $("#state_id").val();
	var severity_id = $("#severity_id").val();
	var n = getIssue ( issue_id );

	var url = "/api/v1/update-issue";
	var getdata = {
		  "issue_id"		: issue_id
		, "title"			: $("#title").val()
		, "body"			: $("#thebody").val()
		, "state_id"		: state_id
		, "severity_id"		: severity_id
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	console.log ( "issue_id=", issue_id, "window.g_data=", window.g_data, "getdata=", getdata, "url=", url );
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "success AJAX update issue", data );
			renderSuccess ( "Issue Updated", "" );
			render5SecClearMessage ( );
			
			saveIssue ( 
				issue_id,
				getdata["title"],
				getdata["body"],
				state_id,
				severity_id
			);

// ---------------------------------------------------------------- This Spot
//	@get('/api/v1/add-note-to-issue')

			console.log ( "<> <> <> g_data=", g_data );
			for ( var ii = 0, mx = window.g_data.n_note; ii < mx; ii++ ) {
				var need_update = false;
				var newTitle = $(`#note_title_${ii}`).val();
				var newBody = $(`#note_body_${ii}`).val();
				console.log ( "at ", ii, "body=", newBody, "old=", window.g_data.note_data[0].note[ii].body );
				if ( newBody === window.g_data.note_data[0].note[ii].body ) {
				} else {
					need_update = true;
					console.log ( "at:   Needs to be updated - body" );
				}
				if ( newTitle === window.g_data.note_data[0].note[ii].title ) {
				} else {
					need_update = true;
					console.log ( "at:   Needs to be updated - title" );
				}
				if ( need_update || window.g_data.add_note ) {
					var note_id = window.g_data.note_data[0].note[ii].id;
					var add_note = window.g_data.note_data[0].note[ii]["add_note"];
					if ( add_note ) {
						addNote ( issue_id, newTitle, newBody, ii );
						window.g_data.note_data[0].note[ii].add_note = undefined;
					} else {
						updateNote ( issue_id, note_id, newTitle, newBody );
					}
				}
			}

			// window.g_data = {};
			renderDashboard();
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			// $("#output-dbg").text( "Error!"+JSON.stringify(resp) );
			// alert("got error status="+resp.status+" "+resp.statusText);
			var msg = resp.statusText;
			renderError ( "Failed to Update Issue", msg );
			render5SecClearMessage ( );
		}
	});
}

function updateNote ( issue_id, note_id, title, body ) {
	var url = "/api/v1/update-note";
	var getdata = {
		  "issue_id"		: issue_id
		, "note_id"			: note_id
		, "title"			: ( title ? title : " " )
		, "body"			: ( body ? body : " " )
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "success AJAX update note on issue", data );
			// renderSuccess ( "Note Updated", "" );
			// render5SecClearMessage ( );
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "Failed to Update Note", msg );
			render5SecClearMessage ( );
		}
	});
}
function addEmptyNote() {
	window.g_data.add_note = true;
	console.log ( "In addEmptyNote ============================================================ ", g_data );
	var note_data = {};
	var issue_id = window.g_data["issue_id"];
	if ( window.g_data.n_note ) {
		var n_note = window.g_data.n_note+1;
		console.log ( "   existing notes ----- appending 1 new one, old n_note=", n_note );
		window.g_data["n_note"] = n_note;
		note_data = window.g_data["note_data"][0];
		window.g_data["note_data"][0]["n_rows_note"] = n_note;
		console.log ( "  new n_note = ", n_note );
		window.g_data.note_data[0].note.push ( {
			"title": "",
			"body": "",
			"id": guid(),
			"ii": n_note-1,
			"issue_id": issue_id,
			"add_note": true
		} );
	} else {
		console.log ( "   >>>>>>>>>>>>>>>>>>>> 0 notes before this -- creating 1 new one" );
		window.g_data["n_note"] = 1;
		var n_note = 1;
		var n = getIssue(issue_id);
		n["n_note"] = 1;
		n["note"] = [];
		window.g_data["note_data"] = [ n ];
		window.g_data["note_data"][0]["n_rows_note"] = n_note;
		window.g_data["note_data"][0]["note"] = [];
		window.g_data.note_data[0].note.push ( {
			"title": "",
			"body": "",
			"id": guid(),
			"ii": n_note-1,
			"issue_id": issue_id,
			"add_note": true
		} );
		console.log ( "  append new n_note = ", n_note );
	}

	var ss = [
		`<table id="note_table" style="width:100%;margin-bottom:10px;">`
	];
	for ( var ii = 0; ii < n_note; ii++ ) {
		ss.push ( [
			  "<tr>"
			,	`<td> <span id="note_no_${ii}"> I am a Note ${ii} </span> </td>`
			, "</tr>"
		].join("\n") );
	}
	ss.push ( "</table>" );

	$("#paint-notes").html( ss.join("\n") );

	for ( var ii = 0; ii < n_note; ii++ ) {
		// var yt = data.data[0].note[ii];
		var yt = window.g_data.note_data[0].note[ii];
		yt["ii"] = ii;
		$(`#note_no_${ii}`).html("").mustache("dom-template-Note", yt )
	}

}
function addNote ( issue_id, title, body, pos ) {
	var url = "/api/v1/add-note-to-issue";
	var getdata = {
		  "issue_id"		: issue_id
		, "title"			: ( title ? title : " " )
		, "body"			: ( body ? body : " " )
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "success AJAX add note on issue", data );
			// renderSuccess ( "Note Updated", "" );
			// render5SecClearMessage ( );
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "Failed to Add Note", msg );
			render5SecClearMessage ( );
		}
	});
}

/*
2. Notes on update - update note / add new note.
	./mt/UpdateIssue.html

	1. postXXX
		1. Make call to get notes
		2. Dynamically Populate them

	@get('/api/v1/add-note-to-issue')
	@get('/api/v1/get-issue-detail')
	@get('/api/v1/update-note')
	id="paint-notes"
			$("#body").html("").mustache("dom-template-"+fn, yt )
*/
function postAddNotesToIssue ( issue_id ) {
	var getdata = {
		  "issue_id"		: issue_id
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	var url = '/api/v1/get-issue-detail';
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "success AJAX get issue detail", data );
		
			var n_note = data.data[0].n_rows_note;
			window.g_data["note_data"] = data.data;
			window.g_data["n_note"] = n_note;

			renderSuccess ( "Issue Details", "<pre>"+JSON.stringify(data,undefined,4)+"</pre>" );
			// console.log ( '***************** n_note=', n_note);

			var ss = [
				`<table id="note_table" style="width:100%;margin-bottom:10px;">`
			];
			for ( var ii = 0; ii < n_note; ii++ ) {
				ss.push ( [
					  "<tr>"
					,	`<td> <span id="note_no_${ii}"> I am a Note ${ii} </span> </td>`
					, "</tr>"
				].join("\n") );
			}
			ss.push ( "</table>" );

			$("#paint-notes").html( ss.join("\n") );

			for ( var ii = 0; ii < n_note; ii++ ) {
				var yt = data.data[0].note[ii];
				yt["ii"] = ii;
				$(`#note_no_${ii}`).html("").mustache("dom-template-Note", yt )
			}

		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "Failed to Update Issue", msg );
			render5SecClearMessage ( );
		}
	});
}


// -----------------------------------------------------------------------------------------------------------------------
// Create Issue Code
// -----------------------------------------------------------------------------------------------------------------------

function preRenderCreateIssue () {
	console.log ( "pre CreateIssue" );
	var issue_id = guid();
	window.g_data["issue_id"] = issue_id;
}
function postRenderCreateIssue () {
	console.log ( "post CreateIssue" );
	var issue_id = window.g_data["issue_id"];

	// Populate the 2 dropdowns.

	var s = renderSelect ( "state_id", "1", state_select_data, issue_id, "css-class-create-state" );
	$("#paint-state").html(s);

	var s = renderSelect ( "severity_id", "1", severity_select_data, issue_id, "css-class-create-severity" );
	$("#paint-severity").html(s);
}

function saveNewIssue() {
	var issue_id = window.g_data["issue_id"];
	// console.log ( "issue_id = ", issue_id );
	var title = $("#title").val();
	var body = $("#thebody").val();
	var state_id = $("#state_id").val();
	var severity_id = $("#severity_id").val();
	var url = "/api/v1/create-issue";
	saveIssue ( issue_id, title, body, state_id, severity_id );
	var getdata = {
		  "issue_id"		: issue_id
		, "title"			: title
		, "body"			: body
		, "state_id"		: state_id
		, "severity_id"		: severity_id
		, "_ran_" 			: ( Math.random() * 10000000 ) % 10000000
	};
	$.ajax({
		type: 'GET',
		url: url,
		data: getdata,
		success: function (data) {
			console.log ( "Success add isue", data );
			renderSuccess ( "Issue Saved", "Issue: "+issue_id+" successfully saved." );
			render5SecClearMessage ( );
			renderDashboard();
			window.g_data = {};
		},
		error: function(resp) {
			console.log ( "error AJAX", resp );
			var msg = resp.statusText;
			renderError ( "Failed to Create Issue", msg );
			render5SecClearMessage ( );
		}
	});
}




// -----------------------------------------------------------------------------------------------------------------------
// Cache of issues and other data for lookup in UI
// -----------------------------------------------------------------------------------------------------------------------
var issue_data = {};

var severity_data = {
	"Unknown": 1,
	"Minor": 2,
	"Documentation Error": 3,
	"Code Chagne": 4,
	"User Interface Change": 5,
	"Severe - System down": 6,
	"Critial - System down": 7
};
var severity_selet_data = [
	{ "value": 1, "name": 'Unknown' },
	{ "value": 2, "name": 'Minor' },
	{ "value": 3, "name": 'Documentation Error' },
	{ "value": 4, "name": 'Code Chagne' },
	{ "value": 5, "name": 'User Interface Change' },
	{ "value": 6, "name": 'Severe - System down' },
	{ "value": 7, "name": 'Critial - System down' }
];
var state_data = {
	"Created": 1,
	"Verified": 2,
	"In Progress": 3,
	"Development Complete": 4,
	"Unit Test": 5,
	"Integration Test": 6,
	"Tests Passed": 7,
	"Documentation": 8,
	"Deployed": 9
};
var state_selet_data = [
	{ "value": 1, "name": 'Created' },
	{ "value": 2, "name": 'Verified' },
	{ "value": 3, "name": 'In Progress' },
	{ "value": 4, "name": 'Development Complete' },
	{ "value": 5, "name": 'Unit Test' },
	{ "value": 6, "name": 'Integration Test' },
	{ "value": 7, "name": 'Tests Passed' },
	{ "value": 8, "name": 'Documentation' },
	{ "value": 9, "name": 'Deployed' }
];


function saveIssue ( issue_id, title, body, state, severity ) {
	severity = ( severity ) ? severity : "Unknown";
	var severity_id = ( severity ) ? severity_data[severity] : 1;
	state = ( state ) ? state : "Created";
	var state_id = state_data[state];
	issue_data[issue_id] = {
		  "title": title	
		, "body": body	
		, "id": issue_id
		, "state": state
		, "state_id": state_id
		, "severity": severity
		, "severity_id": severity_id
	};
}
function getIssue ( issue_id ) {
	return issue_data[issue_id];
}



// -----------------------------------------------------------------------------------------------------------------------
//function preRenderLoginPage () {
//	console.log ( "pre" );
//}
//function postRenderLoginPage () {
//	window.g_data = {};
//	console.log ( "post" );
//}


