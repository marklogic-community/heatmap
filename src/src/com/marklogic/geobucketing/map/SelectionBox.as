// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.

package com.marklogic.geobucketing.map{
	import com.yahoo.maps.api.core.location.BoundingBox;
	import com.yahoo.maps.api.core.location.LatLon;
	import com.yahoo.maps.api.markers.Marker;
	
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import mx.utils.GraphicsUtil;


	public class SelectionBox extends Marker{
		private var handles:Array;
		private var line:Shape;
		private var _geoBounds:BoundingBox;
		
		public var handleSize:Number = 6;
		public var isSizing:Boolean = true;		
		
		
		///// CONSTRUCTOR
		public function SelectionBox(){
			super();
			line = new Shape();
			this.addChild(line);
			handles = new Array();
			var half:Number = handleSize/2;
			for (var i:Number = 0; i<4; i++){
				var handle:Sprite = new Sprite();
				handle.name = "handle" + i;
				handle.graphics.lineStyle(1, 0xffffff, 0);
				handle.graphics.beginFill(0x000000, 0);
				handle.graphics.drawRect(half*-1,half*-1,handleSize,handleSize);
				addChild(handle);
				handles.push(handle);
			}
			handles[0].startDrag();
			addEventListener(Event.ENTER_FRAME, handleOEF,false,0,true);
		}
		
		
		/////PUBLIC	
		public function set geoBounds(p_bb:BoundingBox):void{
			_geoBounds = p_bb;
		}
		public function get geoBounds():BoundingBox{
			return _geoBounds;
		}
		
				
		public function stopHandleDrag():void{
			handles[0].stopDrag();
			isSizing = false;
		}
		
		
		
		
		
		
		//// PROTECTED METHODS
		protected function handleOEF(p_evt:Event):void{
			if (isSizing){
				handles[1].x = handles[0].x;
				handles[2].y = handles[0].y;
				refreshLine();
				setBoundingBox();
			}
		}		
		protected function refreshLine():void{
			line.graphics.clear();
			line.graphics.lineStyle(1,0xffffff,1);
			line.graphics.beginFill(0xffffff, .3);
			line.graphics.moveTo(handles[0].x, handles[0].y);
			line.graphics.lineTo(handles[1].x, handles[1].y);
			line.graphics.lineTo(handles[3].x, handles[3].y);
			line.graphics.lineTo(handles[2].x, handles[2].y);
			line.graphics.lineTo(handles[0].x, handles[0].y);
		}
		protected function setBoundingBox():void{
			//handle 3 is top left (northwest)
			//handle 1 is top right (northeast)
			//handle 2 is bottom left (southwest)
			//handle 0 is bottom right (southeast)
			var northEastPoint:Point = new Point(width, 0);
			var southWestPoint:Point = new Point(0, height);
			var northEastLatLon:LatLon = this.getLocalPointToLatLon(northEastPoint);
			var southWestLatLon:LatLon = this.getLocalPointToLatLon(southWestPoint);
			this.geoBounds = new BoundingBox(southWestLatLon, northEastLatLon);
		}
		
	}
}