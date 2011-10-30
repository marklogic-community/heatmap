// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.

package com.marklogic.geobucketing.map{
	//import ca.spintechnologies.heatmap.sprite.Block;
	
	import com.yahoo.maps.api.core.location.BoundingBox;
	import com.yahoo.maps.api.markers.Marker;
	
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
    
	public class GeoGrid extends Marker{
		
		public static var SELECTION_COMPLETE:String = "ca.spintechnologies.heatmap.GeoGrid";
		
		protected var gridBlocks:Array;
		protected var selectionBox:SelectionBox;
		//protected var border:Shape;
		protected var mapBounds:BoundingBox;
		
		//CONSTRUCTOR    
		public function GeoGrid(p_bounds:BoundingBox, p_width:Number, p_height:Number, p_xSteps:Number = 3, p_ySteps:Number = 3 ){
			super();
			mapBounds = p_bounds;
			//border = new Shape();
			//border.graphics.lineStyle(1,1);
			//border.graphics.beginFill(0x000000, .5);			
			gridBlocks = new Array();
			var len:Number = p_xSteps * p_ySteps;
			
			var xSpace:Number = (p_width-1)/p_xSteps;
			var ySpace:Number = (p_height-1)/p_ySteps;
			/*
			for (var i:Number = 0; i<len; i++){
				var block:Block = new Block();
				block.x = (i%p_xSteps * xSpace);
				block.y = (Math.floor(i/p_xSteps)) * ySpace;
				block.width = xSpace;
				block.height = ySpace;				
				block.label = i.toString();
				addChild(block);
				gridBlocks.push(block);
			}
			*/
			
			this.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown, false, 0 , true);
			this.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp, false, 0 , true);
		}	
		
		//// PUBLIC methods
		public function removeGrid():void{
			var len:Number = gridBlocks.length;
			for(var i:Number = 0; i<len; i++){
				this.removeChild(gridBlocks[i]);
			}
		}
		
		public function getSelectionPosition():Point{
			return new Point(selectionBox.x,selectionBox.y);
		}
		
		public function getSelectionHeight():Number{
			return selectionBox.height;
		}
		
		public function getSelectionWidth():Number{
			return selectionBox.width;
		}
		
		public function getSelectionBounds():BoundingBox{
			var northeastPoint:Point = new Point(this.x + this.width, this.y);
			var southwestPoint:Point = new Point(this.x, this.y + this.height);
			return new BoundingBox(this.getLocalPointToLatLon(southwestPoint), this.getLocalPointToLatLon(northeastPoint));
		}
		
		
		public function removeSelection():void{
			//if (selectionBox) this.removeChild(selectionBox);
		}
		
		//// PROTECTED methods
		protected function drawBorder():void{
			
			//border.graphics.moveTo(
		}
		
		protected function handleMouseDown(p_evt:MouseEvent):void{
			if (selectionBox) this.removeChild(selectionBox);
			selectionBox = new SelectionBox();
			selectionBox.x = this.mouseX;
			selectionBox.y = this.mouseY;
			addChild(selectionBox);
		}
		
		protected function handleMouseUp(p_evet:MouseEvent):void{
			if (selectionBox){
				selectionBox.stopDrag();
				dispatchEvent(new Event(GeoGrid.SELECTION_COMPLETE));
			}
		}
	}
}