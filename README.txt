MarkLogic Heatmap Demo
-----------------------

NOTE

As of 2012, this demo's integration with a third-party mapping service API (Yahoo maps) is no longer functional.  

OVERVIEW

This is a deployable version of the heatmap visualization demonstration found at http://heatmaps.demo.marklogic.com (see above, 
the live demo is currently not functional).

This demo shows how MarkLogic Server's geospatial bucketing feature can be combined with its search capabilities
to deliver an interactive heatmap visualization of search results.  This package provides all the necessary files
to deploy this demo on appropriately marked up data sets.  It also includes the Flex source code for the visualization
widget itself, allowing you to adapt the widget to your needs.


USE

This demo will visualize frequencies of results within content that has been marked up with geospatial data.  To start:

1.  Enter a search term and hit the "search" button.
2.  Magnify and re-bucket the results by either 
      - selecting a bucket with the magnifier icon by pressing the command/control key, 
      - increasing the magnification of the map with the zoom tool on the right side of the map, or 
      - click-dragging with the magnifier icon by holding down the command/control key.
3.  Change the dimensions of the buckets by moving the X and Y sliders at the edge of the map.
4.  To return the map to the original search result, press the "Reset" button.
5.  Note: the result displayed in the search result are those found in the viewable area of the map.


CONTENTS

This package consists of the following:

- README.txt -- this file
- src -- the Flex Builder project files along with the source, written in ActionScript 3
- app -- the server deployables including all html, javascript and XQuery assets.  This is designed to
  be the virtual root of a MarkLogic HTTP Server.


INSTALLATION AND CONFIGURATION

To install on an internal environment, please follow the following steps:

1.  Copy contents of entire app directory to a modules database or root of an HTTP Server.

2.  Ensure that the appropriate Geospatial index has been setup for your content.

3.  In index.html, 1 parameter needs altered:
      - Line 23 flashvar appid --> enter your Yahoo Maps application ID.  If you do not have one, please get one at
        https://login.yahoo.com/config/login_verify2?.src=devnet&.done=https%3A%2F%2Fdeveloper.yahoo.com%2Fwsregapp%2F&rl=1
      - As well, the following parameters can be customized on lines 24-31:
           startLat:  The latitude of the geospatial point where the map should be centered on load
           startLon:  The longitude of the geospatial point where the map should be centered on load
           boundingBoxURL:  The URL of the module that defines queries for bounding boxes.  Can be absolute or
                            relative to index.html
           bucketsURL:  The URL of the module that defines queries for buckets.  Can be absolute or relative
                        to index.html
           scaleColors:  Color encodings for frequencies.  There must be five.
           xGridSize:  Default horizontal grid size.
           yGridSize:  Default vertical grid size.
           gridLineWeight:  Line weight for grids.  Use "0" if no grid lines are desired.
	
	
4.  In js/main.js, 2 parameters need to be altered:
      - Line 8 var lex --> this is the name of the containing element of the lexicon in the form "prefix:name."
      - Line 10 var url --> this is the name of the XQuery module to be executed to fill the search results of the HTML page
	
5.  In common-search.xqy:
      - By default, this is set up to work with cts:element-attribute-pair-geospatial-boxes() with attribute values
        equal to "long" and "lat".  If this needs to be adjusted for different geospatial markup, lines 44, 60, and 77
        need to be adjusted with appropriate functions.
      - By default, the only free text heuristic is defined by cts:word-query.  More sophisticated heuristics can
        be introduced on line 38.
      - Other arbitrary queries can be included (such as an xdmp:directory-query) on line 35.
	
6.  In html_search.xqy:
      - Values for displayed search results need to be altered for specific markup including the title of each record
        (line 64), the marked up geospatial locations (line 65) and the desired descriptive text (line 68).

v1.1  October 27, 2008