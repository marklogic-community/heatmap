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

import module namespace rest = "http://marklogic.com/appservices/rest" at "/MarkLogic/appservices/utils/rest.xqy";
import module namespace requests =   "http://marklogic.com/heatmap/requests" at "/../requests.xqy";

(:: used to grab url params, since this endpoint takes none this is just a place-holder incase future versions need it. ::)
let $request := $requests:options/rest:request [@endpoint = "endpoint/default-endpoint.xqy"][1]
let $map  := rest:process-request($request)

(:: Use polyglot markup to make this a HTML5 enable site ::)
return (
		xdmp:set-response-content-type("text/html"),
	    '<!DOCTYPE html>',
		<html xmlns="http://www.w3.org/1999/xhtml" lang="en">
	    	<head>
	        	<title>MarkLogic HeatMap Demo</title>
				<link href='http://fonts.googleapis.com/css?family=Gorditas' rel='stylesheet' type='text/css'/>
				<link href='heatmap.css' rel='stylesheet' type='text/css'/>
				<script type="text/javascript" src="http://maps.googleapis.com/maps/api/js?sensor=false&amp;region=US"></script>
				<script type="text/javascript" src="js/heatmap.js"></script>
				<script type="text/javascript" src="js/heatmap-gmaps.js"></script>
				<script type="text/javascript" src="https://ajax.googleapis.com/ajax/libs/prototype/1.7.0.0/prototype.js"></script>
				<script type="text/javascript" src="js/demo.js"></script>
	        </head>
	        <body>
				<h1>MarkLogic Heapmap Demo</h1>
				<div class="hbox">
					<div id="map_canvas"></div>
					<div id="result_container">
						<div class="searchbox">
							<label for="query">Search: </label>
							<input type="text" id="query"/>
							<button id="search_button">Go!</button>
						</div> <hr />
						<div id="results"></div>
						<hr />
						<div class="result_page">
							<button id="prev" >prev</button>
							<div>  |  </div>
							<button id="next">next</button>
						</div>
					</div>
				</div>
				<div class="footer">Source availible @ <a href="http://code.google.com/p/heatmap-demo/">code.google.com</a> or <a href="https://github.com/marklogic/heatmap">github</a></div>
	        </body>        
		</html>)
