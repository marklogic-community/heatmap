// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.


package com.marklogic.geobucketing.map.event{
	
	import com.yahoo.maps.api.core.location.BoundingBox;
	
	import flash.events.Event;
	
	public class MapEvent extends Event{
		public static var MAP_INITIALIZE:String = "com.marklogic.geobucketing.map.event.MapEvent.MapInitialize";
		public static var SELECTION_WITH_SHIFT:String = "com.marklogic.geobucketing.map.event.MapEvent.SelectionWithShift";
		public static var SELECTION_WITH_CTRL:String = "com.marklogic.geobucketing.map.event.MapEvent.SelectionWithCTRL";
		public static var MAP_TYPE_CHANGED:String = "com.marklogic.geobucketing.map.event.MapEvent.MapTypeChanged";
		public static var MAP_DRAG_START:String = "com.marklogic.geobucketing.map.event.MapEvent.MapDragStart";
		public static var MAP_DRAG_STOP:String = "com.marklogic.geobucketing.map.event.MapEvent.MapDragStop";
		public static var MAP_DOUBLE_CLICK:String = "com.marklogic.geobucketing.map.event.MapEvent.MapDoubleClick";
		public static var BUCKET_CLICK:String = "com.marklogic.geobucketing.map.event.MapEvent.BucketClick";

		public var maxFrequency:int;
		public var mapType:String;
		public var bounds:BoundingBox;
		public var gridBounds:BoundingBox;
				
		public function MapEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}

	}
}