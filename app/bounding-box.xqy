xquery version "0.9-ml"
(: Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved. :)
(:~ 
:  Main module called by mapping widget to get the bounding box of a free text query.  Please note the order of execution from the perspective of the widget is:
:  <ol>
:  <li> Get bounding box for results of query.</li>
:  <li> Get best fit map from Yahoo mapping service</li>
:  <li> Send the bounding box of the viewable map to be bucketed.</li>
:  </ol>
:
:  Please note this module represents the first step of this process.  Unless changes are made to the widget, nothing needs to be configured in this module.
: @author MarkLogic Corporation (CS)
: @version 1.0
:)

import module namespace search = "common-search" at "common-search.xqy"

let $lex := xdmp:get-request-field("lex")
let $query := search:build-query(xdmp:get-request-field("q"), xdmp:get-request-field("constraint"), $lex)
let $shim := xdmp:log(fn:concat("Geo Spatial Widget query: ", $query), "debug")

let $query-box := search:get-result-bounding-box($lex, $query)
let $box := if ($query-box) then
				$query-box
			else
				search:build-bounding-box(xdmp:get-request-field("constraint"))

return
	element {"box"} {
		attribute {"north"} {cts:box-north($box)},
		attribute {"east"} {cts:box-east($box)},
		attribute {"south"} {cts:box-south($box)},
		attribute {"west"} {cts:box-west($box)}
	}