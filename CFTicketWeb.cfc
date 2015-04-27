<!---

CFTicketWeb.cfc

COPYRIGHT & LICENSING INFO
-------------------------------------------------------------------

Copyright 2007 TJ Downes - tdownes@sanative.net - http://www.sanative.net

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

12/12/2006

This CFC grabs events from the TicketWeb Event Link Report and converts the records to a query.
You MUST have a TicketWeb client account to use this CFC. This CFC can also easily be extended to
use the existing code to pull other reports from the site, I just have not had a need to use them.
BE aware, the CGI scripts on TicketWeb require the httpparams to be formed as I have them. It does
not accept FORMFIELD or COOKIE types. These are passed as URL and CGI variables.

This CFC returns a query with the following columns: StartDateTime, Title, Screen (which is the venue),
and TicketCode (which is just the TicketCode, not the full URL string).

3/11/2007
Entire rewrite of the CFTicketWeb.cfc to allow use with the new TicketWeb system.
As of 3/12/2007 the old version will no longer work.
--->
<cfcomponent displayname="CFTicketWeb"
		output="no"
		hint="This CFC gets events from the TicketWeb System and returns the records as a query">

	<!--- Function getEventLinkReport --->
	<cffunction access="remote" 
			name="getEventLinkReport" 
			output="false" 
			returntype="query" 
			displayname="getEventLinkReport" 
			hint="Fetches records from the EventLinkReport on TicketWeb and returns the parsed file as a query.">
			
		<cfargument name="TicketWebUser" 
					type="string" 
					required="true"
					displayname="TicketWebUser"
					hint="The TicketWeb user email address" />
			
		<cfargument name="TicketWebPassword" 
					type="string" 
					required="true"
					displayname="TicketWebPassword"
					hint="The Password." />
			
		<cfargument name="TicketWebOrgID" 
					type="numeric" 
					required="true"
					displayname="TicketWebOrgID"
					hint="The Org ID. This is the org ID stored passed in TicketWeb forms. To get this, log into TicketWeb and view the source on a page that utilizes a form." />
			
		<cfargument name="StartDate" 
					type="date" 
					required="true"
					displayname="StartDate"
					hint="The starting date of the report" />
			
		<cfargument name="EndDate" 
					type="date" 
					required="true"
					displayname="EndDate"
					hint="The end date of the report" />
			
		<cfargument name="TicketWebURL" 
					type="string" 
					required="true"
					displayname="TicketWebURL" 
					default="https://www.ticketweb.com/t3/report/Config.faces"
					hint="The URL to the Ticketweb System. Defaults to the known TicketWeb URL. This could change, so you may need to change this string or feed in a different URL." />
			
		<cfargument name="TicketWebCSVURL" 
					type="string" 
					required="true"
					displayname="TicketWebCSVURL" 
					default="https://www.ticketweb.com/t3/report/CsvView?reportId=EventLink&orgId=#arguments.TicketWebOrgID#&useCache=true"
					hint="The URL to the Ticketweb CSV Report. Defaults to the known TicketWeb CSV URL. This could change, so you may need to change this string or feed in a different URL." />
			
		<cfargument name="TicketWebOrgHomePageURL" 
					type="string" 
					required="true"
					displayname="TicketWebOrgHomePageURL" 
					default="https://www.ticketweb.com/t3/org/Home?orgId=#arguments.TicketWebOrgID#"
					hint="The URL to your Ticketweb Homepage after logging in. This is used to test to see if the session is still active" />
			
		<cfargument name="TicketWebUserAgent" 
					type="string" 
					required="true"
					displayname="TicketWebUserAgent"
					default="#cgi.HTTP_USER_AGENT#"
					hint="The User Agent String" />

		<cfscript>
			var ImportResults = 0;
			var TheRecords = 0;
			var thisRow = 0;
			var thisColumn = 0;
			var thisField = "";
			var toRemove = 0;
			var i = 0;
			var j = 0;
		</cfscript>
		
		<!--- Call TicketWeb Report --->
		<cfsetting enablecfoutputonly="true"/>
		<!--- make an http post to login the TicketWeb user --->
		<cfif NOT StructKeyExists(session, "TicketWebSessionID")>
			
			<cfset login = logInUser(arguments.TicketWebUser, arguments.TicketWebPassword)/>
			
		<cfelse>
		  <!--- Check the TicketWeb member homepage URL to see if we are still logged in --->
			<cfhttp method="get" url="#arguments.TicketWebOrgHomePageURL#" useragent="#arguments.TicketWebUserAgent#" result="sessionTest" resolveurl="no" charset="utf-8">
				<cfhttpparam name="Cookie" value="t3_remember_cookie=false" type="cgi" encoded="false"/>
				<cfhttpparam name="Cookie" value="WT_FPC=" type="cgi" encoded="false"/>
				<cfhttpparam name="Cookie" value="t3_email_cookie=#arguments.TicketWebUser#" type="cgi" encoded="false"/>
				<cfhttpparam name="Cookie" value="JSESSIONID=#session.TicketWebSessionID#" type="cgi" encoded="false"/>
			</cfhttp>
			
			<cfif sessionTest.FileContent CONTAINS "In order to access secure resources, you must first sign in.">
				<!--- we weren't logged in, so we login again --->
				<cfset login = logInUser(arguments.TicketWebUser, arguments.TicketWebPassword)/>
			
			</cfif>
			
		</cfif>
		
		<!--- set the report in TicketWeb's cache --->
		<cfhttp method="post" url="#arguments.TicketWebURL#" useragent="#arguments.TicketWebUserAgent#" resolveurl="no" charset="utf-8">
			<!--- PARAMS MUST STAY IN THIS ORDER TO WORK CORRECTLY --->
			<cfhttpparam name="Cookie" value="t3_remember_cookie=false" type="cgi" encoded="false"/>
			<cfhttpparam name="Cookie" value="WT_FPC=" type="cgi" encoded="false"/>
			<cfhttpparam name="Cookie" value="t3_email_cookie=#arguments.TicketWebUser#" type="cgi" encoded="false"/>
			<cfhttpparam name="Cookie" value="JSESSIONID=#session.TicketWebSessionID#" type="cgi" encoded="false"/>
			<cfhttpparam name="viewForm" value="viewForm" type="url"/>
			<cfhttpparam name="orgId" value="#arguments.TicketWebOrgID#" type="url"/>
			<cfhttpparam name="eid" value="" type="url"/>
			<cfhttpparam name="shiftId" value="" type="url"/>
			<cfhttpparam name="reportId" value="EventLink" type="url"/>
			<cfhttpparam name="orgId" value="#arguments.TicketWebOrgID#" type="url"/>
			<cfhttpparam name="timezoneFields" value="|EVENTDATE|" type="url"/>
			<cfhttpparam name="eventDate_fromDate" value="1997-01-01+00:00:00" type="url"/>
			<cfhttpparam name="viewForm:eventDate_fromDate" value="#DateFormat(arguments.StartDate, 'mm/dd/yyyy')#" type="url"/>
			<cfhttpparam name="viewForm:eventDate_toDate" value="#DateFormat(arguments.EndDate, 'mm/dd/yyyy')#" type="url"/>
			<cfhttpparam name="viewForm:eventDate" value="0" type="url"/>
			<cfhttpparam name="viewForm:EVENTDATE" value="on" type="url"/>
			<cfhttpparam name="viewForm:EVENTNAME" value="on" type="url"/>
			<cfhttpparam name="viewForm:VENUE" value="on" type="url"/>
			<cfhttpparam name="viewForm:URL" value="on" type="url"/>
			<cfhttpparam name="viewForm:group1" value="EVENTDATE" type="url"/>
			<cfhttpparam name="viewForm:group2" value="" type="url"/>
			<cfhttpparam name="viewForm:group3" value="" type="url"/>
			<cfhttpparam name="viewForm:group4" value="" type="url"/>
			<cfhttpparam name="viewForm:group5" value="" type="url"/>
			<cfhttpparam name="viewForm:ShowTemplateReport" value="Run Report" type="url"/>
			<cfhttpparam name="viewForm" value="viewForm" type="url"/>
		</cfhttp>
		
		<!--- get the CSV report using the previously cached report --->
		<cfhttp method="get" url="#arguments.TicketWebCSVURL#" useragent="#arguments.TicketWebUserAgent#" result="ImportResults" resolveurl="no" charset="utf-8">
			<cfhttpparam name="Cookie" value="t3_remember_cookie=false" type="cgi" encoded="false"/>
			<cfhttpparam name="Cookie" value="WT_FPC=" type="cgi" encoded="false"/>
			<cfhttpparam name="Cookie" value="t3_email_cookie=#arguments.TicketWebUser#" type="cgi" encoded="false"/>
			<cfhttpparam name="Cookie" value="JSESSIONID=#session.TicketWebSessionID#" type="cgi" encoded="false"/>
		</cfhttp>
		
		<cfscript>
			TheRecords = QueryNew("StartDateTime, Title, Screen, TicketCode");
			theResults = ListDeleteAt(ImportResults.FileContent, 1, Chr(10));
		</cfscript>
		<!--- Loop through records --->
		<cfloop list="#theResults#" delimiters="#Chr(10)#" index="i">
			<cfif Len(Trim(i))>
				<cfscript>
					//Add a new row to the query
					thisRow = QueryAddRow(TheRecords);
					//use the Java split() function to make use of multiple characters as a single delimiter and make an array at the same time.
					thisRecord = i.split('","');
				</cfscript>
				<!--- Loop through each cell --->
				<cfloop from="1" to="#ArrayLen(thisRecord)#" index="j">
				<cfset thisField = thisRecord[j] />
					<!--- Check the loop number so we can determine which cell to set --->
					<cfswitch expression="#j#">
						<cfcase value="1">
							<cfscript>
								thisColumn = "StartDateTime";
								thisField = Replace(thisField, '"', "", "ALL");
								toRemove = ListLast(thisField, " ");
								thisField = ParseDateTime(Trim(Replace(thisField, toRemove, "", "ALL")));
							</cfscript>
						</cfcase>
						<cfcase value="2">
							<cfset thisColumn = "Title" />
						</cfcase>
						<cfcase value="3">
							<cfset thisColumn = "Screen" />
						</cfcase>
						<cfcase value="4">
							<cfset thisColumn = "TicketCode" />
							<!--- Strip the URL and just leave the code, we don't really need the URL --->
							<cfscript>
								thisField = Replace(thisField, '"', "", "ALL");
								thisField = Replace(thisField, '\\', "", "ALL");
								thisField = ListLast(thisField, "=");
							</cfscript>
						</cfcase>
					</cfswitch>
					<!--- set the data --->
					<cfset QuerySetCell(TheRecords, thisColumn, thisField) />
				</cfloop>
			</cfif>
		</cfloop>
		<cfsetting enablecfoutputonly="false" />

		<cfreturn TheRecords />
		
	</cffunction>
	
	<cffunction access="private"
		name="logInUser"
		output="false"
		returntype="void"
		displayname="logInUser"
		hint="Logs the user into TicketWeb">
			
		<cfargument name="TicketWebUser" 
			type="string" 
			required="true"
			displayname="TicketWebUser"
			hint="The TicketWeb user email address" />
			
		<cfargument name="TicketWebPassword" 
			type="string" 
			required="true"
			displayname="TicketWebPassword"
			hint="The Password." />
			
		<cfargument name="TicketWebUserAgent" 
			type="string" 
			required="true"
			displayname="TicketWebUserAgent"
			default="#cgi.HTTP_USER_AGENT#"
			hint="The User Agent String" />
		
		<cfargument name="TicketWebLoginURL"
			displayname="TicketWebLoginURL"
			default="https://www.ticketweb.com/t3/user/SignInSubmit"
			required="yes"
			type="string"
			hint="The URL to the TicketWeb login"/>
			
		<cfscript>
			var loginResult = 0;
			var cookieList = "";
			var cookieStruct = Structnew();
			var cookieKV = "";
			var cookieKey = "";
			var cookieValue = "";
		</cfscript>
		
		<cfhttp method="post" url="#arguments.TicketWebLoginURL#" useragent="#arguments.TicketWebUserAgent#" result="loginResult" resolveurl="no" charset="utf-8">
			<cfhttpparam name="emailAddress" value="#arguments.TicketWebUser#" type="formfield"/>
			<cfhttpparam name="password" value="#arguments.TicketWebPassword#" type="formfield"/>
		</cfhttp>
			
		<!--- create cookieStruct --->
		<cfset cookieList = loginResult.responseheader['Set-Cookie'] />
		<cfloop from="1" to="#ListLen(cookieList,';')#" index="i">
			<cfset cookieKV = ListGetAt(cookieList,i,";")>
			<cfif ListLen(cookieKV,"=") gt 1>
				<cfset cookieKey = ListGetAt(cookieKV,1,"=")>
				<cfset cookieValue = ListGetAt(cookieKV,2,"=")>
				<cfset structInsert(cookieStruct,cookiekey,cookievalue)>
			</cfif>
		</cfloop> 
			
		<cfset session.TicketWebSessionID = cookieStruct.JSESSIONID />
		
	</cffunction>
	
	<!--- Function getEventLinkReport --->
	<cffunction access="remote" 
			name="getEventReportArrayOfQueries" 
			output="false" 
			returntype="array" 
			displayname="getEventReportArrayOfQueries" 
			hint="Converts the recordset created by getEventLinkReport into an array of queries to allow the records to be grouped in Flex (for repeater controls)">
			
		<cfargument name="TicketWebUser" 
			type="string" 
			required="true"
			displayname="TicketWebUser"
			hint="The TicketWeb user email address" />
			
		<cfargument name="TicketWebPassword" 
			type="string" 
			required="true"
			displayname="TicketWebPassword"
			hint="The Password." />
			
		<cfargument name="TicketWebOrgID" 
			type="numeric" 
			required="true"
			displayname="TicketWebOrgID"
			hint="The Org ID. This is the org ID stored passed in TicketWeb forms. To get this, log into TicketWeb and view the source on a page that utilizes a form." />
			
		<cfargument name="StartDate" 
			type="date" 
			required="true"
			displayname="StartDate"
			hint="The starting date of the report" />
			
		<cfargument name="EndDate" 
			type="date" 
			required="true"
			displayname="EndDate"
			hint="The end date of the report" />
			
		<cfargument name="TicketWebURL" 
			type="string" 
			required="true"
			displayname="TicketWebURL" 
			default="https://www.ticketweb.com/t3/report/Config.faces"
			hint="The URL to the Ticketweb System. Defaults to the known TicketWeb URL. This could change, so you may need to change this string or feed in a different URL." />
			
		<cfargument name="TicketWebCSVURL" 
			type="string" 
			required="true"
			displayname="TicketWebCSVURL" 
			default="https://www.ticketweb.com/t3/report/CsvView?reportId=EventLink&orgId=#arguments.TicketWebOrgID#&useCache=true"
			hint="The URL to the Ticketweb CSV Report. Defaults to the known TicketWeb CSV URL. This could change, so you may need to change this string or feed in a different URL." />
			
		<cfargument name="TicketWebOrgHomePageURL" 
			type="string" 
			required="true"
			displayname="TicketWebOrgHomePageURL" 
			default="https://www.ticketweb.com/t3/org/Home?orgId=#arguments.TicketWebOrgID#"
			hint="The URL to your Ticketweb Homepage after logging in. This is used to test to see if the session is still active" />
			
		<cfargument name="TicketWebUserAgent" 
			type="string" 
			required="true"
			displayname="TicketWebUserAgent"
			default="#cgi.HTTP_USER_AGENT#"
			hint="The User Agent String" />
					
		<cfscript>
			var Events = getEventLinkReport(arguments.TicketWebUser,arguments.TicketWebPassword,arguments.TicketWebOrgID,arguments.StartDate,arguments.EndDate);
			var EventArray = ArrayNew(1);
			var LoopCount = 0;
			var EventQuery = 0;
			var thisRow = 0;
		</cfscript>
		
		<cfquery name="OrderedEvents" dbtype="query">
			SELECT
				*
			FROM
				Events
			ORDER BY
				Title
		</cfquery>
		
		<cfoutput query="OrderedEvents" group="Title">
			<cfscript>
				LoopCount = LoopCount + 1;
				EventQuery = QueryNew("StartDateTime, Title, Screen, TicketCode");
			</cfscript>
			<cfoutput>
				<cfscript>
					thisRow = QueryAddRow(EventQuery);
					QuerySetCell(EventQuery, "StartDateTime", StartDateTime);
					QuerySetCell(EventQuery, "Title", Title);
					QuerySetCell(EventQuery, "Screen", Screen);
					QuerySetCell(EventQuery, "TicketCode", TicketCode);
				</cfscript>
			</cfoutput>
			<cfset EventArray[LoopCount] = EventQuery />
		</cfoutput>
		
		<cfreturn EventArray />
					
	</cffunction>

</cfcomponent>