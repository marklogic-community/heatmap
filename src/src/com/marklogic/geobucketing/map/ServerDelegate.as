// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.

package com.marklogic.geobucketing.map{
	import com.marklogic.geobucketing.map.event.ServerEvent;
	import com.marklogic.geobucketing.map.sprite.Bucket;
	import com.yahoo.maps.api.core.location.BoundingBox;
	import com.yahoo.maps.api.core.location.LatLon;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLVariables;
	

	public class ServerDelegate extends EventDispatcher{
		
		//for in-IDE development:
		//public var boundingBoxURL:String = "http://gystworks.emergence.com:8004/demo/bounding-box.xqy";
		//public var bucketsURL:String = "http://gystworks.emergence.com:8004/demo/buckets.xqy";
		
		public var boundingBoxURL:String = "bounding-box.xqy";
		public var bucketsURL:String = "buckets.xqy";		
		
		protected var loader:URLLoader;
		protected var loaderConstraint:URLLoader;
		protected var isInitialRequest:Boolean;
		
		public function ServerDelegate(target:IEventDispatcher=null){
			super(target);
		}		
		
				
		////////
		public function requestBoundsUsingKeyword(p_keyword:String, p_lexID:String):void{
				var request:URLRequest = new URLRequest(boundingBoxURL);
				var params:URLVariables = new URLVariables();
				params.q = p_keyword;
				params.lex = p_lexID;
				request.data = params;
	            loader = new URLLoader();	            
	            loader.addEventListener(IOErrorEvent.IO_ERROR, handleError, false, 0 , true);
	            loader.addEventListener(Event.COMPLETE, handleServerData, false, 0 , true);	
	            isInitialRequest = true;			
	            try { loader.load(request); }
	            catch (error:SecurityError){
	                trace("A SecurityError has occurred.");
					var evt:ServerEvent = new ServerEvent(ServerEvent.NEW_KEYWORD_RESULT_BOUNDING_BOX);
					evt.isSuccess = false;
					dispatchEvent(evt);
	            }
	            finally{
	            	//trace("hey, the load is going through");
	            }
		}
		protected function handleServerData(p_evt:Event):void{
			//trace( "\DATA returned: " + loader.data);
			var xml:XML = new XML(loader.data);
			//<box north="58.3019" east="40.0557" south="21.3069" west="-157.858"/>
			//trace("xml: " + xml.@north);
			var neLL:LatLon = new LatLon(xml.@north, xml.@east);			
			var swLL:LatLon = new LatLon(xml.@south, xml.@west);
			var bounds:BoundingBox = new BoundingBox(swLL, neLL);
			var evt:ServerEvent = new ServerEvent(ServerEvent.NEW_KEYWORD_RESULT_BOUNDING_BOX);
			evt.mapsBounds = bounds;
			dispatchEvent(evt);
			
		}
		
		protected function handleError(p_evt:IOErrorEvent):void{
			trace("IOErrorEvent: " + p_evt.toString());
			var evt:ServerEvent = new ServerEvent(ServerEvent.NEW_KEYWORD_RESULT_BOUNDING_BOX);
			evt.isSuccess = false;
			dispatchEvent(evt);
		}
		
		
		////////////////////////
		public function requestDataWithBounds(	p_bounds:BoundingBox, 
												p_xSteps:Number, 
												p_ySteps:Number,
												p_keyword:String, 
												p_lexID:String,
												p_includeBounds:Boolean = true ):void{
			var request:URLRequest = new URLRequest(bucketsURL);
			var params:URLVariables = new URLVariables();
			if (p_includeBounds){
				params.n = p_bounds.northeast.lat;
				params.e = p_bounds.northeast.lon;
				params.s = p_bounds.southwest.lat;
				params.w = p_bounds.southwest.lon;
			}
			params.x = p_xSteps;
			params.y = p_ySteps;
			params.q = p_keyword;
			params.lex = p_lexID;
			request.data = params;
            loader = new URLLoader();	            
            loader.addEventListener(IOErrorEvent.IO_ERROR, handleErrorServerDataFromBounds, false, 0 , true);
            loader.addEventListener(Event.COMPLETE, handleServerDataFromBounds, false, 0 , true);				
            try { loader.load(request); }
            catch (error:SecurityError){
                trace("A SecurityError has occurred.");
				var serverEvent:ServerEvent = new ServerEvent(ServerEvent.UPDATED_GRID);
				serverEvent.isSuccess = false;
				dispatchEvent(serverEvent);
            }
            finally{
            	//trace("request is being made without SecurityError");
            }
		}
		
		
		
		protected function handleServerDataFromBounds(p_evt:Event):void{
			trace( "handleServerDataFromBounds DATA returned: " + loader.data);
			var xml:XML = new XML(loader.data);
			var buckets:Array = new Array();
			var maxFrequency:Number = 0;
			for each (var node:XML in xml..box){
				var latRange:Array = node.@lat.toString().split(",");
				var lonRange:Array = node.@long.toString().split(",");
				if (latRange[0] != "" && 
					latRange[1] != "" &&
					lonRange[0] != "" &&
					lonRange[1] != ""){
						//trace(latRange[0] + ", " + lonRange[0] + " || " + latRange[1] + ", " + lonRange[1]);
						var bb:BoundingBox = new BoundingBox(new LatLon(latRange[0], lonRange[0]),new LatLon(latRange[1], lonRange[1]));
						var myBucket:Bucket = new Bucket();
						myBucket.boundingBox = bb;
						myBucket.frequency = Number(node.@freq);
						buckets.push(myBucket);
						if (myBucket.frequency > maxFrequency) maxFrequency = myBucket.frequency;
				}
			}
			var serverEvent:ServerEvent = new ServerEvent(ServerEvent.UPDATED_GRID);
			serverEvent.buckets = buckets;
			serverEvent.bucketsString = loader.data;
			serverEvent.maxFrequency = maxFrequency;
			if (isInitialRequest){
				serverEvent.isInitialResult = true;
				isInitialRequest = false;
			}
			//serverEvent.mapsBounds = new BoundingBox(new LatLon(40, 0),new LatLon(0, 40));
			//trace("I have buckets: " + buckets.length);
			dispatchEvent(serverEvent);
		}
		
		protected function handleErrorServerDataFromBounds(p_evt:IOErrorEvent):void{
			trace("handleErrorServerDataFromBoundr IOErrorEvent: " + p_evt.toString());
			var serverEvent:ServerEvent = new ServerEvent(ServerEvent.UPDATED_GRID);
			serverEvent.isSuccess = false;
			dispatchEvent(serverEvent);
		}
		
		
		
		
		///////////////////////////////////////////////////////////////////////
		// FILTERING METHODS: resulting from a ctrl/command selection of map
		
		//these methods duplicate functionality from above and needs refactoring
		
		/////REQUEST new bounds using new constraint
		public function requestBoundsUsingConstraint(p_keyword:String, p_lexID:String, p_constraint:String):void{
			//trace("SENDING CONSTRAINT REQUEWST");
			var request:URLRequest = new URLRequest(boundingBoxURL);
			var params:URLVariables = new URLVariables();
			params.q = p_keyword;
			params.lex = p_lexID;
			params.constraint = p_constraint;
			request.data = params;
            loader = new URLLoader();	            
            loader.addEventListener(IOErrorEvent.IO_ERROR, handleConstriantBoundsDataError, false, 0 , true);
            loader.addEventListener(Event.COMPLETE, handleServerConstriantBoundsData, false, 0 , true);				
            try { loader.load(request); }
            catch (error:SecurityError){
                trace("A SecurityError has occurred.");
				var evt:ServerEvent = new ServerEvent(ServerEvent.NEW_FILTERED_BOUNDING_BOX);
				evt.isSuccess = false;
				dispatchEvent(evt);
            }
            finally{
            	//trace("hey, the load is going through");
            }
		}
		protected function handleServerConstriantBoundsData(p_evt:Event):void{
			//trace( "\DATA returned: " + loader.data);
			var xml:XML = new XML(loader.data);
			//<box north="58.3019" east="40.0557" south="21.3069" west="-157.858"/>
			//trace("xml: " + xml.@north);
			var neLL:LatLon = new LatLon(xml.@north, xml.@east);			
			var swLL:LatLon = new LatLon(xml.@south, xml.@west);
			var bounds:BoundingBox = new BoundingBox(swLL, neLL);
			var evt:ServerEvent = new ServerEvent(ServerEvent.NEW_FILTERED_BOUNDING_BOX);
			evt.mapsBounds = bounds;
			dispatchEvent(evt);
			
		}
		
		protected function handleConstriantBoundsDataError(p_evt:IOErrorEvent):void{
			trace("IOErrorEvent: " + p_evt.toString());
			var evt:ServerEvent = new ServerEvent(ServerEvent.NEW_FILTERED_BOUNDING_BOX);
			evt.isSuccess = false;
			dispatchEvent(evt);
		}

		
		
		
		
		
		//////REQUEST new bounds using keyword and a new constraint
		public function requestFilteredBucketsUsingBounds(	p_keyword:String,
															p_lexID:String,
															p_constraint:String, 
															p_xSteps:Number, 
															p_ySteps:Number															
															):void{
			var request:URLRequest = new URLRequest(bucketsURL);
			var params:URLVariables = new URLVariables();
			params.x = p_xSteps;
			params.y = p_ySteps;
			params.q = p_keyword;
			params.lex = p_lexID;
			params.constraint = p_constraint;
			request.data = params;
            loader = new URLLoader();	            
            loader.addEventListener(IOErrorEvent.IO_ERROR, handleErrorConstraintData, false, 0 , true);
            loader.addEventListener(Event.COMPLETE, handleServerConstraintData, false, 0 , true);				
            try { loader.load(request); }
            catch (error:SecurityError){
                trace("A SecurityError has occurred.");
				var serverEvent:ServerEvent = new ServerEvent(ServerEvent.UPDATED_FILTERED_GRID);
				serverEvent.isSuccess = false;
				dispatchEvent(serverEvent);
            }
            finally{
            	trace("request is being made without SecurityError");
            }
		}
		
		////////callbacks for requestBucketsUsingConstraint
		protected function handleServerConstraintData(p_evt:Event):void{
			var xml:XML = new XML(loader.data);
			var buckets:Array = new Array();
			var maxFrequency:Number = 0;
			for each (var node:XML in xml..box){
				var latRange:Array = node.@lat.toString().split(",");
				var lonRange:Array = node.@long.toString().split(",");
				if (latRange[0] != "" && 
					latRange[1] != "" &&
					lonRange[0] != "" &&
					lonRange[1] != ""){
						var bb:BoundingBox = new BoundingBox(new LatLon(latRange[0], lonRange[0]),new LatLon(latRange[1], lonRange[1]));
						var myBucket:Bucket = new Bucket();
						myBucket.boundingBox = bb;
						myBucket.frequency = Number(node.@freq);
						buckets.push(myBucket);
						if (myBucket.frequency > maxFrequency) maxFrequency = myBucket.frequency;
				}
			}
			var serverEvent:ServerEvent = new ServerEvent(ServerEvent.UPDATED_FILTERED_GRID);
			serverEvent.buckets = buckets;
			serverEvent.bucketsString = loader.data;
			serverEvent.maxFrequency = maxFrequency;
			dispatchEvent(serverEvent);
		}
		protected function handleErrorConstraintData(p_evt:IOErrorEvent):void{
			trace("handleErrorConstraintData IOErrorEvent: " + p_evt.toString());
			var serverEvent:ServerEvent = new ServerEvent(ServerEvent.UPDATED_FILTERED_GRID);
			serverEvent.isSuccess = false;
			dispatchEvent(serverEvent);
		}
				
	}
}
		
