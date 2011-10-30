xquery version "0.9-ml"
(: Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved. :)
(:~ 
:  Main module called by mapping widget to get the buckets of a bounding box, contrained by a free text query.  
:  Please note the order of execution from the perspective of the widget is:
:  <ol>
:  <li> Get bounding box for results of query.</li>
:  <li> Get best fit map from Yahoo mapping service</li>
:  <li> Send the bounding box of the viewable map to be bucketed.</li>
:  </ol>
:
:  Please note this module represents the third step of this process.  Unless changes are made to the widget, nothing needs to be configured in this module.
:
: @author MarkLogic Corporation (CS)
: @version 1.0
:)

import module namespace search = "common-search" at "common-search.xqy"


let $lex := xdmp:get-request-field("lex")
let $x-blocks := xs:integer(xdmp:get-request-field("x"))
let $y-blocks := xs:integer(xdmp:get-request-field("y"))
let $north := xdmp:get-request-field("n")
let $east := xdmp:get-request-field("e")
let $south := xdmp:get-request-field("s")
let $west := xdmp:get-request-field("w")

let $shim := xdmp:log(fn:string-join(($south,$west,$north,$east), ","))
let $query := search:build-query(xdmp:get-request-field("q"), xdmp:get-request-field("constraint"), $lex)
let $shim := xdmp:log(fn:concat("Geo Spatial Widget query: ", $query), "debug")


let $query-box := search:get-result-bounding-box($lex, $query)
let $result-box :=  if (($north and $east and $south and $west)) then  
						(cts:box(xs:double($south), xs:double($west), xs:double($north), xs:double($east)), xdmp:log("Widget defined"))
					else if ($query-box) then
						($query-box, xdmp:log("Query defined"))
					else (search:build-bounding-box(xdmp:get-request-field("constraint")), xdmp:log("Constraint defined"))

let $bounds := cts:box(cts:box-south($result-box) - 0.0001, if (cts:box-west($result-box) <= -180) then -179.9999 else cts:box-west($result-box) - 0.0001, cts:box-north($result-box) + 0.0001, if (cts:box-east($result-box) >= 180) then 179.9999 else cts:box-east($result-box) + 0.0001)

let $shim := xdmp:log(fn:concat(
		" South: ",
		cts:box-south($bounds),
		" North: ",
		cts:box-north($bounds),
		" West: ",
		cts:box-west($bounds),
		" East: ",
		cts:box-east($bounds)
	), "debug")

let $lat-step := (cts:box-north($bounds) - cts:box-south($bounds)) div $y-blocks
let $lat-bounds := (cts:box-south($bounds), for $i in (1 to $y-blocks) return cts:box-south($bounds) + $i * $lat-step)

let $long-step := (cts:box-east($bounds) - cts:box-west($bounds)) div $x-blocks
let $long-bounds := (cts:box-west($bounds), for $i in (1 to $x-blocks) return cts:box-west($bounds) + $i * $long-step)

let $shim := xdmp:log("Lat Step", "debug")
let $shim := xdmp:log($lat-step, "debug")

let $shim := xdmp:log("Long Step", "debug")
let $shim := xdmp:log($long-step, "debug")


let $shim := xdmp:log("Lat Edges", "debug")
let $shim := xdmp:log($lat-bounds, "debug")

let $shim := xdmp:log("Long Edges", "debug")
let $shim := xdmp:log($long-bounds, "debug")


let $shim := xdmp:log("Lat bounds")
let $shim := xdmp:log($lat-bounds[2 to fn:last() - 1], "debug")

let $shim := xdmp:log("Long bounds")
let $shim := xdmp:log($long-bounds[2 to fn:last() - 1], "debug")

return

<grid lat-step="{$lat-step}" long-step="{$long-step}" north="{cts:box-north($bounds)}" east="{cts:box-east($bounds)}" south="{cts:box-south($bounds)}" west="{cts:box-west($bounds)}">
{
	let $result-buckets := search:get-result-buckets($lex, $query, $lat-bounds, $long-bounds)
	let $shim := xdmp:log(
		for $i in $result-buckets
		return xdmp:log(fn:concat(
		"South: ",
		cts:box-south($i),
		" North: ",
		cts:box-north($i),
		" West: ",
		cts:box-west($i),
		" East: ",
		cts:box-east($i),
		" Frequency: ",
		cts:frequency($i)
	))
	, "debug")
				
			for $boxes in $result-buckets
			return
			if (cts:box-south($boxes) >= cts:box-south($bounds) and
				cts:box-west($boxes) >= cts:box-west($bounds) and
				cts:box-north($boxes) <= cts:box-north($bounds) and
			    cts:box-east($boxes) <= cts:box-east($bounds)
				) then
				element {"box"} {
					attribute {"lat"} {fn:concat(cts:box-south($boxes), ",", cts:box-north($boxes))},
					attribute {"long"} {fn:concat(cts:box-west($boxes), ",", cts:box-east($boxes))},
					attribute {"freq"} {
						cts:frequency($boxes)
					}
				}
			else ()
}
</grid>
