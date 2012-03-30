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

import module namespace json = "http://marklogic.com/json" at "/MarkLogic/appservices/utils/json.xqy";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace requests =   "http://marklogic.com/heatmap/requests" at "/../requests.xqy";

declare namespace entity="http://marklogic.com/entity";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

(:: this query being used by both map and text result formats to filter out results that exist outside of the give bounding box ::)
declare function local:get-map-query($south, $west, $north, $east){
	cts:element-attribute-pair-geospatial-query(
      xs:QName("entity:gpe"), 
      xs:QName("lat"),
      xs:QName("long"), 
      cts:box($south,$west,$north,$east))
};

(:: grab / process all parameters passed to the search endpoint ::)
let $request := $requests:options/rest:request [@endpoint = "endpoint/search-endpoint.xqy"][1]
let $map  := rest:process-request($request)
let $type := map:get($map, "type")
let $format := map:get($map, "format")
let $q := map:get($map, "q")
let $north := map:get($map, "north")
let $east := map:get($map, "east")
let $south := map:get($map, "south")
let $west := map:get($map, "west")
let $page := xs:integer(if(fn:exists(map:get($map, "page"))) then map:get($map, "page") else 1)

(:: two different search interfaces are used to provide map results vs. text results, this handles the differences in query formats when the query is empty ::)
let $map-query := if(fn:exists($q) and $q ne "") then $q else "*"
let $text-query := if(fn:exists($q)) then $q else ""

let $result := 
		(:: makes use of the Geospatial index defined in the database config. this is how we get really fast results for the heatmap ::)
		if($type eq "map") then
			let $loc := cts:element-attribute-pair-geospatial-values(
			      xs:QName("entity:gpe"),
			      xs:QName("lat"),
			      xs:QName("long"),
			      (),
			      ("item-frequency"),
			      cts:and-query((
			        local:get-map-query($south, $west, $north, $east)
			      ,
			        cts:word-query($map-query, ("case-insensitive","whitespace-insensitive","wildcarded","diacritic-insensitive"))
			      ))
			   )
			return
				(:: format the search results into the expected format ::)
				<result>{
				for $l in $loc
				  return
				    <data>
				      <lat>{cts:point-latitude($l)}</lat>
				      <lng>{cts:point-longitude($l)}</lng>
				      <count>{cts:frequency($l)}</count>
				    </data>
				}</result>
		else
			(:: 
			
			this section is used for text results; here we use the search api to find / fetch the differenct article titles, 
			links, and other keywords found in that article.
			
			by setting the start index as well as the page length we can control the resutlt pagination
			
			 ::)
			let $hits := search:search($text-query,
			  <search:options>
			    <search:additional-query>{local:get-map-query($south, $west, $north, $east)}</search:additional-query>
				<search:term>
				   <search:empty apply="all-results" />
				   <search:term-option>wildcarded</search:term-option>
				   <search:term-option>punctuation-insensitive</search:term-option>
				 </search:term>
			    <search:transform-results apply="raw">
			      <search:preferred-elements>
			        <search:element ns="http://marklogic.com/entity" name="gpe"/>
			      </search:preferred-elements>
				  <search:max-snippet-chars>150</search:max-snippet-chars>
				  <search:per-match-tokens>20</search:per-match-tokens>
			    </search:transform-results>
			  </search:options>, $page, 10
			)

			return
				(:: format the text search results ::)
				<result>
				<total>{fn:data($hits/@total)}</total>
				<page>{fn:data($hits/@start)}</page>
			{	
			  for $h in $hits/search:result
			    return
			      <data>
			        <title>{fn:substring-after(fn:data($h/html/body/xhtml:div[@class eq "cnnBlogContentTitle"]/xhtml:a/@title),"Permanent Link: ")}</title>
					<link>{fn:data($h/html/body/xhtml:div[@class eq "cnnBlogContentTitle"]/xhtml:a/@href)}</link>
					<keywords>{fn:replace(fn:string-join(fn:distinct-values($h//entity:gpe/text())," | "),",","")}</keywords>
			      </data>
			}
  				</result>

(:: finally return the results, this final step has the option of converting the results to a JSON format ::)
return
  if($format eq "json") then json:serialize($result)
  else if($format eq "xml") then $result
  else fn:concat("bad format request: ", $format, " : ", map:key($map)) (:: if a bad format (not XML or JSON) is passed in pass back an error + all of the parameter names ::)