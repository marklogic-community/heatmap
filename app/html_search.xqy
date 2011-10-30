xquery version "0.9-ml"
(: Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved. :)

(:~ 
:  Main module called by AJAX within js/main.js.  Only changes that are required the XPaths within the <result> element to extract the content from the markup.
:
: @author MarkLogic Corporation (CS)
: @version 1.0
:)

import module namespace search = "common-search" at "common-search.xqy"

declare namespace entity = "http://marklogic.com/entity"
declare namespace xhtml = "http://www.w3.org/1999/xhtml"

define function strip-entities($element)
{
	element {fn:name($element)}
	{
		$element/attribute::*,
		for $i in $element/(node()|text())
		return
			if (fn:node-kind($i) = "element" and fn:namespace-uri($i) = "http://www.w3.org/1999/xhtml") then
				strip-entities($i)
			else if (fn:node-kind($i) = "element") then
				$i/text()
			else $i
	}

}

let $lex := xdmp:get-request-field("lex")
let $query := search:build-query(xdmp:get-request-field("q"), xdmp:get-request-field("constraint"), $lex)
let $shim := xdmp:log(fn:concat("Page query: ", $query), "debug")
let $start := xs:integer(xdmp:get-request-field("s"))
let $end := xs:integer(xdmp:get-request-field("n")) - $start + 1
let $search := cts:search(fn:input()/html, $query, "unfiltered")[$start to $end]
return
<search>
	{
	if (xdmp:get-request-field("facet")) then
		<facets>
		{
			for $facet in fn:tokenize(xdmp:get-request-field("facet"), ",")
			return
			<facet name="{$facet}">
			{
				for $facet-values in cts:element-attribute-values(xs:QName($facet), xs:QName("canonical"), (), ("frequency-order"), $query)[1 to 10]
				return <value freq={search:add-commas(cts:frequency($facet-values))}>{$facet-values}</value>
				
			}
			</facet>
		}
		</facets>
	else ()
	}
	<results estimate="{if ($search) then search:add-commas(xdmp:estimate(cts:search(fn:input()/html, $query))) else 0}">
	{
		for $i in $search
		return 
		(: Content here may need to be altered to fit the content :)
		<result>			
					<title>{fn:substring-after(fn:data($i/body/xhtml:div[@class = "BlogContentTitle"]/xhtml:a/@title), "Permanent Link: ")}</title>
					<locations>{fn:string-join(fn:distinct-values($i/body//(entity:GPE|entity:gpe)/text()), ", ")}</locations>
					<text>
					{	
						for $hit-fragment in cts:highlight($i, $query, <xhtml:div class="match">{$cts:text}</xhtml:div>)//xhtml:div[@class="match"]//parent::*:p
						return strip-entities($hit-fragment)			
					}
					</text>
					<url>{fn:data($i/body/xhtml:div[@class = "cnnBlogContentTitle"]/xhtml:a/@href)}</url>
				</result>
	}
	</results>
</search>