
// Copyright (C) Philip Schlump, 2012.

// Render of Tables into .html

function qt(tmpl, ns, fx) {
	if ( typeof fx == "undefined" ) { fx = {} };
	var p1 = tmpl.replace(/%{([A-Za-z0-9_|.,]*)%}/g, function(j, t) {
			var pl;
			var s = "";
			var a = t.split("|");
			for ( var i = 0; i < a.length; i++ ) {
				// console.log ( "ts1: a["+i+"] =["+a[i]+"]" );
				pl = a[i].split(",");
				// console.log ( "ts1: pl[0] =["+pl[0]+"]"+"  typeof for this =="+typeof fx[pl[0]] );
				if ( typeof fx [ pl[0] ] === "function" ) {
					var fx2 = fx[ pl[0] ];
					s = fx2(s,ns,pl);									// Now call each function as a pass thru-filter
				} else if ( typeof ns [ pl[0] ] === "string" || typeof ns [ pl[0] ] === "number" ) {
					s = ns[ pl[0] ];
				} else {
					s = "";
				}
			}
			return s;
		});
	return p1;
};


// 2 parts to a render - the header config, the per-row config.
// You pass in the data, a array of data hashes .

// toId 	- #id - where table is to be renderd to.
// data 	-
// hdrCfg 	-
// rowCfg 	-

function renderTableTo ( toId, data, hdrCfg, p_rowCfg ) {
	var out = [];

	out.push ( '<table class="table ', hdrCfg.TableClass, '">\n' );

	// -------------------- header ------------------------------------------------------------------
	out.push ( ' <thead>\n' );
	out.push ( '   <tr>\n' );
	for ( var ii = 0, mx = hdrCfg.ColNames.length; ii < mx; ii++ ) {
		out.push ( "       <th>", hdrCfg.ColNames[ii].Name, "</th>\n" );
	}
	out.push ( '   </tr>\n' );
	out.push ( ' </thead>\n' );

	// -------------------- body ------------------------------------------------------------------
	out.push ( ' <tbody>\n' );
	// xyzzy -- TODO -- xyzzy
	for ( var ii = 0, mx = data.length; ii < mx; ii++ ) {
		out.push ( '   <tr>\n' );
		var row = data[ii];
		for ( var jj = 0, my = p_rowCfg.cols.length; jj < my ; jj++ ) {
			var rowCfg = p_rowCfg.cols[jj];
			var colName = rowCfg.Name;
			var fx1 = rowCfg.fx;
			var colData = row[colName];
			if ( ! colData ) {
				colData = "";
				if ( rowCfg.defaltValue ) {
					colData = rowCfg.defaltValue;
				}
			} else if ( rowCfg.defaultIfEmpty && colData == "" ) {
				colData = rowCfg.defaltIfEmpty;
			}
			// add template - by Col Pos, by Row/Col pos override.
			if ( rowCfg.rowTmpl ) {
				// console.log ( "Calling qt with", rowCfg.rowTmpl, row);
				colData = qt(rowCfg.rowTmpl, row);
			} 
			if ( rowCfg.rowColTmpl && rowCfg.rowColTmpl[jj] ) {
				// xyzzy - this needs work.
				colData = qt(rowCfg.rowColTmpl[jj], row);
			}
			// xyzzy - TODO add in col-position _1st, _last, _odd, _even
			// xyzzy - TODO - check for func, template etc...
			if ( typeof fx1 === "function" ) {
				out.push ( fx1 ( colData, row, data, ii, jj, colName ) );
			} else {
				out.push ( '       <td>', colData , '</td>\n' );
			}

		} 
		out.push ( '   </tr>\n' );
	}
	out.push ( ' </tbody>\n' );

	out.push ( '</table>\n' );

	var sOut = out.join("");
console.log ( sOut );

	$(toId).html ( sOut );
}

var x_data = [
	{
		"Name": "Bob",
		"Value": 23,
		"id": "123-id-abc"
	},
	{
		"Name": "Jane",
		"Value": 28,
		"id": "123-id-def"
	},
];

var actionUrlTmpl = "/api/v2/user-edit?id=%{id%}&__method__=POST&_ran_=%{ran%}&act=%{act%}&%{data%}"
function ActionFunc ( idCol, fullRow, fullTableData, rowNum, colNum, colName ) {
	return qt ( [ '',
		'       <td>\n',
		'         <button type="button" class="btn btn-primary bind-click" data-click="submitUpdate" data-id="%{id%}">Update</button>\n',
		'         <button type="button" class="btn btn-primary bind-click" data-click="submitDelete" data-id="%{id%}">Delete</button>\n',
		'       </td>\n',
	].join(""), fullRow );
}

var x_hdrCfg = {
	ColNames: 	[ { Name:"Name"}, 		{ Name:"Value" }, 		{ Name:"Action" } 	],
};

var x_rowCfg = {
	cols: [
			{ Name: "Name" },
			{ Name: "Value", rowTmpl: "$%{Value%}" },
			{ Name: "id", fx: ActionFunc },
// Name - column nmae
// fx - fuctnion that if set will have data past to it - more powerful - but code - for maping instead of using templates.
// defaultValue - a default if no column value is supplied.
// defaultIfEmpty - a default if "" is the value supplied
// rowTmpl - a QT tempaltes - this allows for wrapping a column with HTML using a template
// rowColTmpl - a hash by column name of QT tempaltes - this allows for wrapping a column/row number with stuff.
	]
};

renderTableTo ( "#output", x_data, x_hdrCfg, x_rowCfg );
