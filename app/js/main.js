// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.
window.onload = initAll;
window.onunload = function() {};

/*Global Vars*/

//  The geospatial lexicon to be used for bucketing.  Must in the format of ns_prefix:local name.
var lex = "entity:gpe"
// The relative URL of the XQuery module that is accessed by the HTML page to populate its results
var url = "html_search.xqy"

var qString = location.search;
var qValue = unescape(qString.substring(qString.indexOf("q=") + 2, qString.length)).replace(/\+/g, " ");

var sQuery;

var xhr=null;

var UIwidth = 734;
var facetBoxGap = 10;

var sStr = ""
var sFacets = ""
var resultsTextLength = 150
var n = 10
var s = 1

var constraintStr = ""
var loaded = false;

var ieversion;

if (/MSIE (\d+\.\d+);/.test(navigator.userAgent)){ 
	ieversion = new Number(RegExp.$1) 
}
else {
	ieversion = 0;
}

function initAll(){
	thisMovie('GeoBucketingMap').focus();
	document.getElementById("search").onclick = getNewPost;
    //setup to handle keypress events
    var elem
    elem = document.getElementById("searchKeyword");

    // assign event handlers for modern DOM browsers
    if (elem) {
        elem.onkeypress = handleEnterKeyPress
    }
    
    if (qValue != "") {
    	document.getElementById("searchKeyword").value = qValue;	
    }
    
   	getNewPost()
}

function getNewPost(){
	sFacets = ""
	
	var mySearch = document.getElementById("searchKeyword");
	sStr = mySearch.name + "=" + mySearch.value
	
	sQuery = mySearch.value
	
	newSearch()

	if (sQuery == "") {
		makeRequest()
	}
}

function mapLoaded() {
	setTimeout("thisMovie('GeoBucketingMap').searchByKeywordFromBrowser(sQuery, lex)", 0);
}


function newSearch(){
	constraintStr = ""
	if(loaded){
		setTimeout("thisMovie('GeoBucketingMap').searchByKeywordFromBrowser(sQuery, lex)", 0);
	}
	loaded = true;
}

function makeRequest(){
	
	var urlSearch = url + "?q" + sStr + "&s=" + s + "&n=" + n + "&lex=" + lex
	if (constraintStr != "") {
	   urlSearch += "&constraint=" + constraintStr

	}
	
	if(window.XMLHttpRequest){
		xhr = new XMLHttpRequest();
	}else{
		if(window.ActiveXObject){
			try{
				xhr = new ActiveXObject("Microsoft.XMLHTTP");
			}
			catch(e){}
		}
	}
	if(xhr){
		//alert(xhr);
		xhr.onreadystatechange = showContents;
		xhr.open("GET", urlSearch, true);
		xhr.send(null);
	}else{
		document.getElementsById("updateArea").innerHTML = "Sorry, but I couldn't create an XMLHttprequest";
	}
}

function showContents(){
	//alert("showing content")
	var outMsg = "loading..." + xhr.readyState;
	if(xhr.readyState == 4){
		if(xhr.status == 200){
			//makeFacetsLists()
			makeDetailList()
			}else{
			var outMsg = "there was a problem with the request " + xhr.status;
			document.getElementById("updateArea").innerHTML = outMsg;
		}
	}
}

function addConstraint(north, south, east, west){
	constraintStr = "s:"+south+";w:"+west+";n:"+north+";e:"+east;
	makeRequest()
}

var getChildElements = function(node)
{
    var a = [];
    var tags = node.getElementsByTagName("*");
    
    for (var i = 0; i < tags.length; ++i)
    {
        if (node == tags[i].parentNode)
        {
            a.push(tags[i]);
        }
    }
    return a;
} 

function makeDetailList(){
	var myResults = xhr.responseXML.getElementsByTagName("result")
	var outLabel = null
	outLabel = "<div id=resultsLabel>" + xhr.responseXML.getElementsByTagName("results")[0].nodeName + " (" + xhr.responseXML.getElementsByTagName("results")[0].attributes.getNamedItem("estimate").value + ") </div>"
	var outMsg = null
	outMsg = "<div id=resultsList><table id='resultsTable'>"
	
	if (ieversion >= 6) {
		for(i=0;i<myResults.length;i++){
			var childElements = getChildElements(myResults[i]);
			//outMsg += "<tr>"
			outMsg += "<td class='resultsItem'><a href='"+childElements[3].text+"' target='_blank'>" + childElements[0].text + "</a><br />"
			if(childElements[2].text != ""){
				outMsg +=  childElements[2].text + "<br />"
			}
			if(childElements[1].text != ""){
				outMsg +=  "<span class='locations'>" + childElements[1].text + "</span><br />"
			}
			outMsg += "</td></tr>"				
		}
	} 
	else {
		for(i=0;i<myResults.length;i++){
			var childElements = getChildElements(myResults[i]);
			//outMsg += "<tr>"
			outMsg += "<td class='resultsItem'><a href='"+ childElements[3].textContent +"' target='_blank'>" + childElements[0].textContent + "</a><br />"
			if(childElements[2].textContent != ""){
				outMsg +=  childElements[2].textContent + "<br />"
			}
			if(childElements[1].textContent != ""){
				outMsg +=  "<span class='locations'>" + childElements[1].textContent + "</span><br />"
			}
			outMsg += "</td></tr>"				
		}
	}
	outMsg += "</table></div>";
	document.getElementById("updateArea").innerHTML = outLabel + outMsg;
}
function handleEnterKeyPress(evt) {
    evt = (evt) ? evt : ((window.event) ? window.event : "")
    if (evt) {
    	if(evt.keyCode==13){
    		getNewPost()
    	}
    }
}



/*1. ÊInitial call from webpage to widget (javascript to externalized AS function)

	newSearch(query, lex) where
	query = inputted query string
	lex = the id of the geo spatial lexicon
	
	Makes call to bounding-box.xqy with the following parameters in header (POST or GET will work)
	
	q = text of search
	lex = the id of the geo spatial lexicon
	
	After retrieving the map, make a call to buckets.xqy with the following parameters in header (POST or GET will work)
	
	q = text of search
	lex = the id of the geo spatial lexicon
	x = the number horizontal buckets
	y = the number of vertical buckets
	
	By excluding the swne coordinates, the bonding box will be defined by the results of the query.

	
2. ÊCall to server to redraw the bounding box (internal AS function)

	Makes call to buckets.xqy with the following parameters in header (POST or GET will work)

	q = text of search
	lex = the id of the geo spatial lexicon
	x = the number horizontal buckets
	y = the number of vertical buckets
	n = the north edge of the viewable map
	s = the north edge of the viewable map
	e = the east edge of the viewable map
	w = the west edge of the viewable map

	By including the swne coordinates, the bonding box will be defined by the edges of the box defined.

	
3. ÊSelecting a box to filter by (i.e. filter) (AS calling external JS function, JS function calling externalized AS function)

	a. ÊMakes a call to the containing HTML page via js:
	
	addConstraint(north, east, south, west)
	
	
north = the north edge of the selected box
	south = the north edge of the selected box
	east = the east edge of the selected box
	west = the west edge of the selected box

		
	b. ÊPage will format the constraints and call the following externalized AS function:
	
	newConstraint(query, lex, constraint)
	
	query = inputted query string
	lex = the id of the geo spatial lexicon
	constraint = the filter by constraints to be parsed by the middleware
	
	Makes call to bounding-box.xqy with the following parameters in header (POST or GET will work)
	
	q = text of search
	lex = the id of the geo spatial lexicon
	
constraint = the filter by constraints, as a string, to be parsed by the middleware in the form of s:12;w:10;n=40;e:20
	
	After retrieving the map, make a call to buckets.xqy with the following parameters in header (POST or GET will work)
	
	q = text of search
	lex = the id of the geo spatial lexicon
	x = the number horizontal buckets
	y = the number of vertical buckets	
	constraint = the filter by constraints, as a string, to be parsed by the middleware in the form of s:12;w:10;n=40;e:20
	
	By excluding the swne coordinates, the bonding box will be defined by the results of the query.
	
	*/
