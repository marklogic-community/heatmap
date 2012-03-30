(:
Copyright 2012 MarkLogic Corporation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
:)


xquery version "1.0-ml";

module namespace requests="http://marklogic.com/heatmap/requests";

import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";

declare option xdmp:mapping "false";

declare variable $requests:options as element(rest:options) :=
  <rest:options>
	(:: if a user goes to the root url path, redirect to 'heatmap' ::)
	<rest:request uri="^/$" endpoint="/redirect.xqy">
        <rest:uri-param name="__ml_redirect__">/heatmap</rest:uri-param>
    </rest:request>
	
	(:: renders content on the default-endpoint, also accepts a 'q' param in the query string (no currently used) ::)
  	<rest:request uri="^/heatmap$" endpoint="endpoint/default-endpoint.xqy">
		<rest:param name="q" as="string" match="(.+)">$1</rest:param>
  	</rest:request>
	
	(:: redirect for legacy demo links ::)
	<rest:request uri="^/demo/$" endpoint="/redirect.xqy">
		<rest:uri-param name="__ml_redirect__">/heatmap</rest:uri-param>
	</rest:request>
	
	(:: renders content on the search-endpoint, also used to validate the various parameters passed to that endpoint ::)
	<rest:request uri="^/search/(map|text).(xml|json)$" endpoint="endpoint/search-endpoint.xqy">
		<rest:uri-param name="type">$1</rest:uri-param>
		<rest:uri-param name="format">$2</rest:uri-param>
		<rest:param name="q" as="string" match="(.+)" default="*">$1</rest:param>
		<rest:param name="page" as="integer" match="(\d+)">$1</rest:param>
		<rest:param name="north" as="double" match="(\d+\.\d+)">$1</rest:param>
		<rest:param name="east" as="double" match="(\d+\.\d+)">$1</rest:param>
		<rest:param name="south" as="double" match="(\d+\.\d+)">$1</rest:param>
		<rest:param name="west" as="double" match="(\d+\.\d+)">$1</rest:param>
  	</rest:request>
	
  </rest:options>;