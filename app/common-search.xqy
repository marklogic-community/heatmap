xquery version "0.9-ml"
(: Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved. :)
(:~ 
: Main library module for all cts:query operation for geospatial widget.  All changes to adjust for particular form of geo spatial markup are made here.
:
: @author MarkLogic Corporation (CS)
: @version 1.1
:)

module "common-search"

declare namespace entity = "http://marklogic.com/entity"


define variable $lat-QName as xs:QName {xs:QName("lat")}
define variable $long-QName as xs:QName {xs:QName("long")}


(:~ 
: Function that builds the free-text query, optionally constrained by a geospatial bounding box.
:
: @param $query-string The free text to search for in the database.
: @param $filters SWNE coordinates that define the constraining bounding box.  A string in the form n:21;e:54;s:76;w:87.
: @param $$element-qname The name of the element containing the geospatial data.  May be in the form prefix:local-name.  If so,
: the appropriate element namespace declaration must be made in this module.
: @return cts:query
:)
define function build-query($query-string as xs:string, $filters as xs:string*, $element-qname as xs:string) as cts:query
{
		cts:and-query((
			
			(: Place any other arbitrary query types here.  Both the widget and the HTML page will have their search queries funneled to this function :)
			cts:directory-query("/", "infinity"),
			
			(: This is the free text portion of the query.  If a more sophisticated heuristic is required, it should be replaced here. :)
			if ($query-string != "") then cts:word-query($query-string, ("case-insensitive", "punctuation-insensitive")) else (),
			
			(: This is for widget defined filters  by clicking and dragging. :)
			if ($filters != "") then
				let $box := build-bounding-box($filters)
				(: If one needs to change the appropriate query to better match the markup the geospatial content, change it here.  :)
				return cts:element-attribute-pair-geospatial-query(xs:QName($element-qname), $lat-QName, $long-QName, $box)
			else ()
		))		
}

(:~ 
: Function that fetches a bounding-box of geospatial points within the database, as constrained by a query.
:
: @param $lex The name of the element containing the geospatial data.  May be in the form prefix:local-name.  If so,
: the appropriate element namespace declaration must be made in this module.  Must also define the appropriate Geospatial Lexicon
: within MarkLogic Server.
: @param $query The query object that defines the constraints to bound the results within.
: @return A sequence of cts:box types
:)
define function get-result-bounding-box($lex as xs:string, $query as cts:query)
{
	cts:element-attribute-pair-geospatial-boxes(xs:QName($lex), $lat-QName, $long-QName, (), (), (), $query)
}


(:~ 
: Function that fetches buckets of geospatial points within the database, as constrained by a query.
:
: @param $lex The name of the element containing the geospatial data.  May be in the form prefix:local-name.  If so,
: the appropriate element namespace declaration must be made in this module.  Must also define the appropriate Geospatial Lexicon
: within MarkLogic Server.
: @param $query The query object that defines the constraints to bound the results within.
: @param $lat-bounds A sequence of xs:double types, for each horizontal boundary of the desired set of buckets
: @param $long-bounds A sequence of xs:double types, for each vertical boundary of the desired set of buckets
: @return A sequence of cts:box types
:)
define function get-result-buckets($lex as xs:string, $query as cts:query, $lat-bounds as xs:double*, $long-bounds as xs:double*)
{
	cts:element-attribute-pair-geospatial-boxes(xs:QName($lex), $lat-QName,$long-QName, $lat-bounds, $long-bounds, ("gridded", "empties"), $query)
}

(:~ 
: Function that constructs a cts:box from a semi-colon delimeted string of SWNE coordinates.
:
: @param filters An xs:string type in the form n:21;e:54;s:76;w:87.
: @return cts:box
:)
define function build-bounding-box($filters as xs:string)
{
	let $filter := fn:tokenize($filters, ";")
	return
	cts:box(
		xs:float(fn:substring-after($filter[fn:contains(., "s")], ":")),
		xs:float(fn:substring-after($filter[fn:contains(., "w")], ":")),
		xs:float(fn:substring-after($filter[fn:contains(., "n")], ":")),
		xs:float(fn:substring-after($filter[fn:contains(., "e")], ":"))
	)
}

(:~ 
: Utility function to add comma separations to numbers.  e.g.  1000 -> 1,000
:
: @param $num An integer to be commafied
: @return A string representing a commafied version of the inputed number.
:)
define function add-commas($num as xs:integer)
{
	 fn:string-join(
		 fn:reverse(
			 for $i at $x in fn:reverse(for $i in fn:string-to-codepoints(xs:string($num)) return fn:codepoints-to-string($i))
			 return
			 if ($x > 1 and ($x - 1) mod 3 = 0) then 
			 	fn:concat($i, ",") 
			 else $i
		 )
	 , "")
}