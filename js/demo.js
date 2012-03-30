/**

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

**/

var map = null;
var heatmap = null;
var ne = null;
var sw = null;
var current_page = 1;

/** 
  fires after the DOM loads; is used to setup some global variables and register the various event handlers 
**/
function init(){
	var myOptions = {
	          center: new google.maps.LatLng(39.5, -98.35),
	          zoom: 4,
	          mapTypeId: google.maps.MapTypeId.ROADMAP
	        };
	
	map = new google.maps.Map(document.getElementById("map_canvas"), myOptions);
	
	// had to make a few modifications to the provided heatmap-gmaps.js to work with this project
	heatmap = new HeatmapOverlay(map, {"radius":15, "visible":true, "opacity":60});
	
	// updates the search results when the map bounds change.
	google.maps.event.addListener(map, 'idle', function(){
		update_results();
	});
	
	// updates the search results when the search box is in focus and the 'enter' key is pressed.
	Event.observe('query', 'keyup', function(event){
		if(event.keyIdentifier == "Enter"){
			update_results();
		}
	});
	
	// updates the search results when the search button is clicked.
	Element.observe('search_button', 'click', function(event){
		update_results();
	});
	
	// updates the text results only with the next page
	Element.observe('next', 'click', function(event){
		update_text_results(current_page+1);
	});
	
	// updates the text results only with the previous page
	Element.observe('prev', 'click', function(event){
		if(current_page > 1){
			update_text_results(current_page-1);
		}
	});
}

/**
  function grabs the updated map bounds and uses and AJAX request to update the heatmap and the text results.
**/
function update_results(){
	ne = map.getBounds().getNorthEast();
	sw = map.getBounds().getSouthWest();
	
	new Ajax.Request('/search/map.json',{
		method:'get',
		parameters: {q:$('query').value, north:ne.lat(), east:ne.lng(), south:sw.lat(), west:sw.lng()},
		onSuccess: function(resp){
			var mapdata = resp.responseText.evalJSON(true);
			heatmap.setDataSet({
				max: 3, // this parameter is used to adjust the heatmaps radial gradient alpha transition.
				data: mapdata.result.data
			});
			
			heatmap.draw();
		}
	});
	
	update_text_results(1);
}

/**
  used to update the text results via an AJAX call.
**/
function update_text_results(newpage){
	if(ne == null || sw == null){
		console.error("bad map bounds!")
		return
	} else {
	
		new Ajax.Request('/search/text.json',{
			method:'get',
			parameters: {q:$('query').value, north:ne.lat(), east:ne.lng(), south:sw.lat(), west:sw.lng(), page:((1+newpage*10)-10)},
			onSuccess: function(resp){
				current_page = newpage;
				$('results').innerHTML = "";
				
				var textdata = resp.responseText.evalJSON(true);
				
				$('results').insert(new Element('div',{'class':'total_results'}).update("Total: " + textdata.result.total + " -- Page: " + current_page));
				textdata.result.data.each(function(i){				
					var article = new Element('div', { 'class': 'article'});
					var title = new Element('a',{'class':'title', href: i.link}).update(i.title);
					var keywords = new Element('div',{'class':'keywords'}).update(i.keywords);
				
					article.insert(title);
					article.insert(keywords);
					
					Element.insert('results',article);
				});
			}
		});
	}
}

document.observe('dom:loaded', init);