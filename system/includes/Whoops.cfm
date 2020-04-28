<cfscript>
	if ( !structKeyExists( variables, "strLimit" ) ) {
		variables.strLimit = function( str, limit, ending = "..." ){
			if ( len( str ) <= limit ) {
				return str;
			}
			return mid( str, 1, limit ) & ending;
		};
	}

	// Detect Session Scope
	local.sessionScopeExists = getApplicationMetadata().sessionManagement;

	try {
		local.thisInetHost = createObject( "java", "java.net.InetAddress" ).getLocalHost().getHostName();
	} catch ( any e ) {
		local.thisInetHost = "localhost";
	}

	local.eventDetails = {
		"Error Code"    : ( oException.getErrorCode() != 0 ) ? oException.getErrorCode() : "",
		"Type"          : oException.gettype(),
		"Extended Info" : ( oException.getExtendedInfo() != "" ) ? oException.getExtendedInfo() : "",
		"Message"       : htmlEditFormat( oException.getmessage() ).listChangeDelims( "<br>", chr( 13 ) & chr( 10 ) ),
		"Detail"        : htmlEditFormat( oException.getDetail() ).listChangeDelims( "<br>", chr( 13 ) & chr( 10 ) ),
		"Event"         : ( event.getCurrentEvent() != "" ) ? event.getCurrentEvent() : "",
		"Route"         : ( event.getCurrentRoute() != "" ) ? event.getCurrentRoute() & (
			event.getCurrentRoutedModule() != "" ? " from the " & event.getCurrentRoutedModule() & "module router." : ""
		) : "",
		"Route Name"       : ( event.getCurrentRouteName() != "" ) ? event.getCurrentRouteName() : "",
		"Routed Module"    : ( event.getCurrentRoutedModule() != "" ) ? event.getCurrentRoutedModule() : "",
		"Routed Namespace" : ( event.getCurrentRoutedNamespace() != "" ) ? event.getCurrentRoutedNamespace() : "",
		"Routed URL"       : ( event.getCurrentRoutedURL() != "" ) ? event.getCurrentRoutedURL() : "",
		"Layout"           : ( Event.getCurrentLayout() != "" ) ? Event.getCurrentLayout() : "",
		"Module"           : event.getCurrentLayoutModule(),
		"View"             : event.getCurrentView(),
		"itemorder"        : [
			"Error Code",
			"Type",
			"Message",
			"Detail",
			"Extended Info",
			"Event",
			"Route",
			"Route Name",
			"Routed Module",
			"Routed Namespace",
			"Routed URL",
			"Layout",
			"Module",
			"View"
		]
	};

	local.frameworkSnapshot = {
		"Coldfusion ID"  : "Session Scope Not Enabled",
		"Template Path"  : CGI.CF_TEMPLATE_PATH,
		"Path Info"      : CGI.PATH_INFO,
		"Host"           : CGI.HTTP_HOST,
		"Server"         : local.thisInetHost,
		"Query String"   : CGI.QUERY_STRING,
		"Referrer"       : CGI.HTTP_REFERER,
		"Browser"        : CGI.HTTP_USER_AGENT,
		"Remote Address" : CGI.REMOTE_ADDR,
		"itemorder"      : [
			"Coldfusion ID",
			"Template Path",
			"Path Info",
			"Host",
			"Server",
			"Query String",
			"Referrer",
			"Browser",
			"Remote Address"
		]
	};

	if ( local.sessionScopeExists ) {
		local.fwString = "";
		if ( isDefined( "client" ) ) {
			if ( structKeyExists( client, "cfid" ) ) fwString &= "CFID=" & client.CFID;
			if ( structKeyExists( client, "CFToken" ) ) fwString &= "<br/>CFToken=" & client.CFToken;
		}
		if ( isDefined( "session" ) ) {
			if ( structKeyExists( session, "cfid" ) ) fwString &= "CFID=" & session.CFID;
			if ( structKeyExists( session, "CFToken" ) ) fwString &= "<br/>CFToken=" & session.CFToken;
			if ( structKeyExists( session, "sessionID" ) ) fwString &= "<br/>JSessionID=" & session.sessionID;
		}
		frameworkSnapshot[ "Coldfusion ID" ] = fwString;
	}

	local.databaseInfo = {};
	if (
		(
			isStruct( oException.getExceptionStruct() )
			OR findNoCase( "DatabaseQueryException", getMetadata( oException.getExceptionStruct() ).getName() )
		) AND findNoCase( "database", oException.getType() )
	) {
		local.databaseInfo = {
			"SQL State"            : oException.getSQLState(),
			"NativeErrorCode"      : oException.getNativeErrorCode(),
			"SQL Sent"             : oException.getSQL(),
			"Driver Error Message" : oException.getqueryError(),
			"Name-Value Pairs"     : oException.getWhere()
		};
	}
	</cfscript>

	<cfset local.e = oException.getExceptionStruct()/>
	<cfset stackFrames = arrayLen( local.e.TagContext )/>

<cfoutput>
	<html>
		<head>
			<title>ColdBox Whoops! An error occurred!</title>
			<script src="/coldbox/system/includes/js/eva.min.js"></script>
			<script src="/coldbox/system/includes/js/syntaxhighlighter.js"></script>
			<script src="/coldbox/system/includes/js/javascript-brush.js"></script>
			<script src="/coldbox/system/includes/js/coldfusion-brush.js"></script>
			<link type="text/css" rel="stylesheet" href="/coldbox/system/includes/css/syntaxhighlighter-theme.css">
			<link type="text/css" rel="stylesheet" href="/coldbox/system/includes/css/whoops.css">
			<script>
				SyntaxHighlighter.defaults[ 'gutter' ] 		= true;
				SyntaxHighlighter.defaults[ 'smart-tabs' ] 	= false;
				SyntaxHighlighter.defaults[ 'tab-size' ]   	=  4;
				SyntaxHighlighter.all();
			</script>
		</head>
		<body>
			<div class="whoops">

				<div class="whoops__nav">

					<!----------------------------------------------------------------------------------------->
					<!--- Top Left Exception Area --->
					<!----------------------------------------------------------------------------------------->
					<div class="exception">

						<div class="exception__logo">
							<img src="/coldbox/system/includes/images/coldbox-logo.png" width="40" />
							<span>ColdBox Exception</span>
						</div>

						<h1 class="exception__timestamp" title="Time of exception">
							<i data-eva="clock-outline" fill="##7fcbe2"></i>
							<span>#dateFormat( now(), "MM/DD/YYYY" )# #timeFormat( now(), "hh:MM:SS TT" )#</span>
						</h1>

						<h1 class="exception__type" title="Error Code and Exception Type">
							<i data-eva="close-circle-outline" fill="red"></i>
							<span>#trim( eventDetails[ "Error Code" ] & " " & local.e.type )#</span>
						</h1>

						<div class="exception__message" title="Exception Message">
							#oException.processMessage( local.e.message )#
						</div>

					</div>

					<!----------------------------------------------------------------------------------------->
					<!--- Stack Frames --->
					<!----------------------------------------------------------------------------------------->

					<div class="whoops_stacktrace_panel_info">Stack Frame(s): #stackFrames#</div>
					<div class="whoops__stacktrace_panel">
						<ul class="stacktrace__list">
							<cfset root = expandPath( "/" )/>
							<cfloop from="1" to="#arrayLen( local.e.TagContext )#" index="i">
								<cfset instance = local.e.TagContext[ i ]/>
								<!--- <cfdump var="#instance#"> --->
								<li
									id   ="stack#stackFrames - i + 1#"
									class="stacktrace <cfif i EQ 1>stacktrace--active</cfif>"
									title="Open Frame"
								>
									<span class="badge">#stackFrames - i + 1#</span>
									<div class="stacktrace__info">
										<h3 class="stacktrace__location">
											#replace( instance.template, root, "" )#:<span class="stacktrace__line-number">#instance.line#</span>
										</h3>
										<cfif structKeyExists( instance, "codePrintPlain" )>
											<cfset codesnippet = instance.codePrintPlain>
											<cfset codesnippet = reReplace( codesnippet, "\n\t", " ", "All" )>
											<cfset codesnippet = htmlEditFormat( codesnippet )>
											<cfset codesnippet = reReplace(
												codesnippet,
												"([0-9]+:)",
												"#chr( 10 )#\1",
												"All"
											)>
											<cfset splitLines = listToArray( codesnippet, "#chr( 10 )#" )>
											<h4 class="stacktrace__code" style="margin-top:-10px;">
												<cfloop array="#splitLines#" index="codeline">
													#strLimit( codeline, 40 )#<br>
												</cfloop>
											</h4>
										</cfif>
									</div>
									<cfif oException.openInEditorURL( event, instance ) NEQ "">
										<a
											target="_self"
											rel   ="noreferrer noopener"
											href  ="#oException.openInEditorURL( event, instance )#"
											class ="editorLink__btn"
											title="Open in Editor"
										>
											<i data-eva="code-download-outline" height="20"></i>
										</a>
									</cfif>
								</li>
							</cfloop>
						</ul>
					</div>
				</div>


				<!----------------------------------------------------------------------------------------->
				<!--- Details Pane --->
				<!----------------------------------------------------------------------------------------->
				<div class="whoops__detail">

					<!----------------------------------------------------------------------------------------->
					<!--- Code Container --->
					<!----------------------------------------------------------------------------------------->
					<cfif stackFrames gt 0>
						<div class="code-preview">
							<cfset instance = local.e.TagContext[ 1 ]/>
							<div id="code-container"></div>
						</div>
					</cfif>

					<!----------------------------------------------------------------------------------------->
					<!--- Exception Details --->
					<!----------------------------------------------------------------------------------------->
					<div class="request-info data-table-container">

						<!----------------------------------------------------------------------------------------->
						<!--- Slide UP Button --->
						<!----------------------------------------------------------------------------------------->

						<div class="slideup_row">
							<a href="javascript:void(0);" onclick="toggleCodePreview()" class="button button-icononly">
								<i id="codetoggle-up" data-eva="arrowhead-up-outline"></i>
								<i id="codetoggle-down" class="hidden" data-eva="arrowhead-down-outline"></i>
							</a>
						</div>

						<!----------------------------------------------------------------------------------------->
						<!--- Scope Filters --->
						<!----------------------------------------------------------------------------------------->

						<div>
							<h2 class="details-heading">
								Exception Details
							</h2>
							<div class="data-filter" title="Filter Scopes">
								<i data-eva="funnel-outline" fill="white"></i>
								<a class="button active" 	href="javascript:void(0);" onclick="filterScopes( this, '' );">All</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'eventdetails' );">Error Details</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'frameworksnapshot_scope' );">Framework Snapshot</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'database_scope' );">Database</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'rc_scope' );">RC</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'prc_scope' );">PRC</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'headers_scope' );">Headers</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'session_scope' );">Session</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'application_scope' );">Application</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'cookies_scope' );">Cookies</a>
								<a class="button" 			href="javascript:void(0);" onclick="filterScopes( this, 'stacktrace_scope' );">Raw Stack Trace</a>
							</div>
						</div>

						<!----------------------------------------------------------------------------------------->
						<!--- Exception Details --->
						<!----------------------------------------------------------------------------------------->
						<cfoutput>
							<div id="request-info-details">
								<div id="eventdetails" class="data-table">
									<label>Error Details</label>
									#oException.displayScope( eventDetails )#
								</div>

								<div id="frameworksnapshot_scope" class="data-table">
									<label>Framework Snapshot</label>
									#oException.displayScope( frameworkSnapshot )#
								</div>

								<div id="database_scope" class="data-table">
									<label>Database</label>
									#oException.displayScope( databaseInfo )#
								</div>

								<div id="rc_scope" class="data-table">
									<label>RC</label>
									#oException.displayScope( rc )#
								</div>

								<div id="prc_scope" class="data-table">
									<label>PRC</label>
									#oException.displayScope( prc )#
								</div>

								<div id="headers_scope" class="data-table">
									<label>Headers</label>
									#oException.displayScope( getHTTPRequestData().headers )#
								</div>

								<div id="session_scope" class="data-table">
									<label>Session</label>
									<cftry>
										#oException.displayScope( session )#
										<cfcatch>
											<em>No Session</em>
										</cfcatch>
									</cftry>
								</div>

								<div id="application_scope" class="data-table">
									<label>Application</label>
									#oException.displayScope( application )#
								</div>

								<div id="cookies_scope" class="data-table">
									<label>Cookies</label>
									#oException.displayScope( cookie )#
								</div>

								<div id="stacktrace_scope" class="data-table">
									<label>Raw Stack Trace</label>
									<div class="data-stacktrace">#processStackTrace( oException.getstackTrace() )#</div>
								</div>
							</div>
						</cfoutput>
					</div>
				</div>
			</div>

			<!----------------------------------------------------------------------------------------->
			<!--- Global File Getters --->
			<!----------------------------------------------------------------------------------------->
			<cfset stime = getTickCount()>

			<cfloop from="1" to="#arrayLen( local.e.TagContext )#" index="i">
				<cfset instance = local.e.TagContext[ i ]/>
				<cfset highlighter = ( listLast( instance.template, "." ) eq "cfm" ? "cf" : "js" )/>
				<pre
					id="stack#stackFrames - i + 1#-code"
					data-highlight-line="#instance.line#"
					style="display: none;"
				>
					<script type="syntaxhighlighter" class="brush:#highlighter#; highlight: [#instance.line#];" async>
						<![CDATA[<cfloop file="#instance.template#" index="line">#line##chr( 13 )#</cfloop>
						]]>
					</script>
				</pre>
			</cfloop>

			<!----------------------------------------------------------------------------------------->
			<!--- End JS Scripts --->
			<!----------------------------------------------------------------------------------------->
			<script src="/coldbox/system/includes/js/whoops.js"></script>
			<script>
				eva.replace();
			</script>
		</body>
	</html>
</cfoutput>