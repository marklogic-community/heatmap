// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.

package com.marklogic.geobucketing.map{
	import com.marklogic.geobucketing.map.event.BrowserEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.external.ExternalInterface;
	


	public class BrowserDelegate extends EventDispatcher{
		public function BrowserDelegate(target:IEventDispatcher=null){
			super(target);
			ExternalInterface.addCallback("searchByKeywordFromBrowser", searchByKeywordFromBrowser);
			ExternalInterface.addCallback("newConstraint", handleNewConstraintFromBrowser);
		}
		
		
		//public methods
		public function requestFilterByBounds(north:Number, south:Number, east:Number, west:Number):void{
			ExternalInterface.call("addConstraint", north, south, east, west);	
		}
		public function sendMapBounds(north:Number, south:Number, east:Number, west:Number):void{
			ExternalInterface.call("addConstraint", north, south, east, west);
		}
		public function sendMapLoaded():void{
			ExternalInterface.call("mapLoaded");
		}
								
		
		//protected methods
		protected function searchByKeywordFromBrowser(p_keyword:String, p_lex:String):void{
			var evt:BrowserEvent = new BrowserEvent(BrowserEvent.SEARCH_BY_KEYWORD);
			evt.keyword = p_keyword;
			evt.lexicon = p_lex;
			dispatchEvent(evt);
		}
		
		protected function handleNewConstraintFromBrowser(p_query:String, p_lexicon:String, p_constraint:String):void{
			var evt:BrowserEvent = new BrowserEvent(BrowserEvent.NEW_CONSTRAINT);
			evt.keyword = p_query;
			evt.lexicon = p_lexicon;
			evt.constraint = p_constraint;
			dispatchEvent(evt);
		}
	}
}



