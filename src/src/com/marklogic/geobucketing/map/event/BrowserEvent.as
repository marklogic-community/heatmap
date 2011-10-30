// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.


package com.marklogic.geobucketing.map.event{
	import flash.events.Event;
	
	public class BrowserEvent extends Event{
		public static var SEARCH_BY_KEYWORD:String = "com.marklogic.geobucketing.map.event.SearchByKeyword";
		public static var NEW_CONSTRAINT:String = "com.marklogic.geobucketing.map.event.NewConstraint";
		
		public var keyword:String;
		public var lexicon:String;
		public var constraint:String;
		
		public function BrowserEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false){
			super(type, bubbles, cancelable);
		}

	}
}