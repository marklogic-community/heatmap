// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.


package com.marklogic.geobucketing.map.event
{
	import com.yahoo.maps.api.core.location.BoundingBox;
	
	import flash.events.Event;

	public class ServerEvent extends Event{
		
		public static var NEW_GRID:String = "com.marklogic.geobucketing.map.event.NewGrid";
		public static var UPDATED_GRID:String = "com.marklogic.geobucketing.map.event.UpdatedGrid";
		public static var UPDATED_FILTERED_GRID:String = "com.marklogic.geobucketing.map.event.UpdatedFilteredGrid";
		public static var NEW_KEYWORD_RESULT_BOUNDING_BOX:String = "com.marklogic.geobucketing.map.event.NewKeywordResultBoundingBox";
		public static var NEW_FILTERED_BOUNDING_BOX:String = "com.marklogic.geobucketing.map.event.NewFilteredBoundingBox";
		public static var SERVER_ERROR:String = "com.marklogic.geobucketing.map.event.ServerError";
		
		public var buckets:Array;
		public var bucketsString:String = ""; // for testing
		public var maxFrequency:Number = 0;
		public var mapsBounds:BoundingBox;
		public var isSuccess:Boolean = true;
		public var isInitialResult:Boolean = false; //this is a flag to indicate that the buckets belong to the base result set
		
		public function ServerEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}
		
	}
}