<!---

test for for CFTicketWeb.cfc

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
The CFC grabs events from the TicketWeb Event Link Report and converts the records to a query.
You MUST have a TicketWeb client account to use the CFC. The CFC can also easily be extended
to use the existing code to pull other reports from the site, I just have not had a need to use
them. Be aware, the CGI scripts on TicketWeb require the httpparams to be formed as I have them.
It does not accept FORMFIELD or COOKIE types. These are passed as URL and CGI variables.

The CFC returns a query with the following columns: StartDateTime, Title, Screen (which is the venue),
and TicketCode (which is just the TicketCode, not the full URL string).

You can also pass a custom URL and User Agent. Refer to the CFC arguments.

12/13/2006
Fixed a minor bug that caused an error indicating start date must be before end date. This was due to an extraneous URL var.
Changed the dates to allow just StartDate and EndDate to be passed to the CFC. The CFC handles the rest to prevent user error.

3/11/2007
Entire rewrite of the CFTicketWeb.cfc to allow use with the new TicketWeb system.
As of 3/12/2007 the old version will no longer work.
--->
<cfinvoke component="com.utils.CFTicketWeb" method="getEventLinkReport" returnvariable="theReport">
	<cfinvokeargument name="TicketWebUser" value="your ticketweb username" />
	<cfinvokeargument name="TicketWebPassword" value="your ticketweb password" />
	<!--- orgID can be found by logging into the TicketWeb system and looking for it in the URL string or Form sourcecode --->
	<cfinvokeargument name="TicketWebOrgID" value="your ticketweb orgid." />
	<cfinvokeargument name="StartDate" value="3/1/2007" />
	<cfinvokeargument name="EndDate" value="3/31/2007" />
</cfinvoke>
<cfdump var="#theReport#" />

