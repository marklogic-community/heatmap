// Copyright 2002-2010 MarkLogic Corporation.  All Rights Reserved.

package com.marklogic.geobucketing.map{
	import com.marklogic.geobucketing.map.event.MapEvent;
	import com.marklogic.geobucketing.map.sprite.Bucket;
	import com.yahoo.maps.api.YahooMap;
	import com.yahoo.maps.api.YahooMapEvent;
	import com.yahoo.maps.api.core.location.BoundingBox;
	import com.yahoo.maps.api.core.location.LatLon;
	import com.yahoo.maps.api.overlays.PolylineOverlay;
	
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import mx.managers.CursorManager;
	
	public class YahooBucketMap extends YahooMap implements IHeatMap{
				
		//this is the runningmap APPID
		public var yahooAppID:String = "PC.4xsbV34HgXBLsGydqcBoXv4IzziFYBKyPsZD_c.NVvx.W_xxkaaUce8BVajYs";
		public var bucketColors:Array = [0xF6DC86, 0xF8BA69, 0xF3995F, 0xEE6651, 0xDE404F];
		public var gridLineWeight:Number = 0.5;
		//protected var gridBlocks:Array;
		public var buckets:Array;
		public var gridLines:Array;
		protected var _selectionBounds:BoundingBox;
		protected var selectionBox:SelectionBox;
		[Embed(source="../../../../../assets/zoom.png")]
		protected var zoomCursor:Class; 
		[Embed(source="../../../../../assets/hand_grab.png")]
		protected var handGrab:Class; 
		[Embed(source="../../../../../assets/hand_open.png")]
		protected var handOpen:Class;
		protected var isShiftDown:Boolean = false;
		protected var isCtrlDown:Boolean = false;
		protected var hasMoved:Boolean = false;
		protected var isMouseDown:Boolean = false;
		protected var tempPoint:Point;
		protected var localPoint:Point;
		protected var mouseLatLon:LatLon;
		protected var frequencyTF:TextField;
		protected var bucketsAreEnabled:Boolean = false;
		public var resultBorder:PolylineOverlay;
		protected var initBounds:BoundingBox;
		protected var draggingOutOfTopBounds:Boolean = false;		
		protected var draggingOutOfBottomBounds:Boolean = false;
		protected var draggingOutOfLeftBounds:Boolean = false;		
		protected var draggingOutOfRightBounds:Boolean = false;
		//protected var baseResultBoundingBox:BoundingBox;
		protected var testTF:TextField;
		
		//constructor
		public function YahooBucketMap(p_width:Number, p_height:Number){
			super();
			buckets = new Array();
			gridLines = new Array();
			this.init(yahooAppID, p_width, p_height);
			this.addPanControl();
			this.addScaleBar();
			this.addEventListener(YahooMapEvent.MAP_INITIALIZE, handleMapInitialize, false, 0, true); 
			this.addEventListener(YahooMapEvent.MAP_TYPE_CHANGED, handleMapTypeChange, false, 0, true);
			this.mapContainer.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown, false, 0, true);
			this.mapContainer.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp, false, 0, true);
			this.mapContainer.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove, false, 0, true);
			this.addEventListener(YahooMapEvent.MAP_DOUBLE_CLICK, handleMapDoubleClick, false, 0, true);
			this.addEventListener(YahooMapEvent.MAP_DRAG_START, handleDragStart, false, 0, true);
			this.addEventListener(YahooMapEvent.MAP_DRAG_STOP, handleDragStop, false, 0, true);
			setCursor("handOpen");
		}
		
		//public methods		
		public function updateBuckets(p_buckets:Array, p_maxFequency:Number):void{ 
			removeBuckets();
			removeGridLines();			
			buckets = p_buckets;
			var len:Number = p_buckets.length;
			var divisor:Number = p_maxFequency/p_buckets[0].bucketColors.length;
			for (var i:uint = 0; i < len; i++){
				p_buckets[i].bucketColors = bucketColors;
				p_buckets[i].gridLineWeight = gridLineWeight;
				p_buckets[i].scaleIndex =  Math.min(Math.floor(p_buckets[i].frequency/divisor), 4);
                var bucket:Bucket = p_buckets[i] as Bucket;
                this.overlayManager.addOverlay(bucket);
                bucket.draw();
                bucket.addEventListener(MouseEvent.CLICK, zoomToBucket, false, 0, true);
   			}
   			if (isCtrlDown) enableBuckets(true);
		}
		
		public function getBucketResultBounds():BoundingBox{
			var maxLat:Number = buckets[0].boundingBox.maxLat;
			var minLat:Number = buckets[0].boundingBox.minLat;
			var maxLon:Number = buckets[0].boundingBox.maxLon;
			var minLon:Number = buckets[0].boundingBox.minLon;
			var len:uint = buckets.length;
			for (var i:uint = 1; i<len; i++){
				maxLat = Math.max(maxLat, buckets[i].boundingBox.maxLat);
				maxLon = Math.max(maxLon, buckets[i].boundingBox.maxLon);
				minLat = Math.min(minLat, buckets[i].boundingBox.minLat);
				minLon = Math.min(minLon, buckets[i].boundingBox.minLon);
			}
			var swLatLon:LatLon = new LatLon(minLat, minLon);
			var neLatLon:LatLon = new LatLon(maxLat, maxLon);			
			var gridBounds:BoundingBox = new BoundingBox(swLatLon, neLatLon);
			return gridBounds;
		}
		
		public function get bucketWidth():Number{
			var _bucketWidth:Number = 0;
			if (buckets.length > 0) _bucketWidth = Math.abs(buckets[0].boundingBox.maxLon - buckets[0].boundingBox.minLon);
			return _bucketWidth;
		}
		public function get bucketHeight():Number{
			var _bucketHeight:Number = 0;
			if (buckets.length > 0) _bucketHeight = Math.abs(buckets[0].boundingBox.maxLat - buckets[0].boundingBox.minLat);
			return _bucketHeight;
		}
		public function hasBuckets():Boolean{
			return (buckets.length > 0);
		}
		
		
		public function drawGrid():void{
			if (gridLineWeight <= 0) return;			
			gridLines = new Array();			
			var resultBounds:BoundingBox = getBucketResultBounds();
			var gridHeight:Number = bucketHeight;
			var gridWidth:Number = bucketWidth;
			var lineColor:uint = 0x000000;
			var lineAlpha:Number = 0.2;
			
			//super(lineColor, lineAlpha, lineThickness, geodesic);
			
			var lat:Number = resultBounds.maxLat; 			
			while (lat < 90){
				var line:PolylineOverlay = new PolylineOverlay(lineColor, lineAlpha, gridLineWeight);
				this.overlayManager.addOverlay(line);
				var lineData:Array = new Array(new LatLon(lat, -180), new LatLon(lat, 180));
				line.dataProvider = lineData;
				gridLines.push(line);
				lat += gridHeight;
			}
			
			lat = resultBounds.maxLat;
			lat -= gridHeight;
			while (lat > - 90){
				line = new PolylineOverlay(lineColor, lineAlpha, gridLineWeight);
				this.overlayManager.addOverlay(line);
				lineData = new Array(new LatLon(lat, -180), new LatLon(lat, 180));
				line.dataProvider = lineData;
				gridLines.push(line);
				lat -= gridHeight;
			}
			
			var lon:Number = resultBounds.maxLon;
			while (lon < 180){
				line = new PolylineOverlay(lineColor, lineAlpha, gridLineWeight);
				this.overlayManager.addOverlay(line);
				lineData = new Array(new LatLon(90, lon), new LatLon(-90, lon));
				line.dataProvider = lineData;
				gridLines.push(line);
				lon += gridWidth;
			}
			
		 	lon = resultBounds.maxLon;
		 	lon -= gridWidth;
			while (lon > -180){
				line = new PolylineOverlay(lineColor, lineAlpha, gridLineWeight);
				this.overlayManager.addOverlay(line);
				lineData = new Array(new LatLon(90, lon), new LatLon(-90, lon));
				line.dataProvider = lineData;
				gridLines.push(line);
				lon -= gridWidth;
			} 
		}	
		
		
				
		public function drawResultBorder(p_bounds:BoundingBox):void{
			try{
				this.overlayManager.removeOverlay(resultBorder);
			}catch(e:Error){};
			resultBorder = new PolylineOverlay(0x000000, 1, 1);
			resultBorder.fillAlpha = 0;
			resultBorder.lineThickness = 0.1;
			this.overlayManager.addOverlay(resultBorder);
			resultBorder.drawBoundingBox(p_bounds);
			resultBorder.mouseEnabled = false;  
		}
		

		///////////////////////////protected methods		
		protected function setCursor(p_type:String):void{
			CursorManager.removeAllCursors();
			switch (p_type){
				case "handOpen":								
					CursorManager.setCursor(handOpen,3,-8,-8);
					break;
				case "handGrab":
					CursorManager.setCursor(handGrab,3,-8,-8)
					break;					
				case "zoom":								
					CursorManager.setCursor(zoomCursor,3,-4,-4);
					break;
				case "default":
				default:
					CursorManager.removeAllCursors();
					break;
			}
		}
		
		
		
		
		/*****************************
		 * MOUSE EVENT HANDLERS
		 * ***************************/
		protected function handleMouseDown(event:MouseEvent):void{
			isMouseDown = true;				
			if (!isCtrlDown) setCursor("handGrab");
			else{
				hasMoved = false;
				enableBuckets(true);
			}
			try{this.removeEventListener(Event.ENTER_FRAME, handleCrtlDownOEF);}catch(e:Error){}
		}
		
		protected function handleMouseUp(p_evt:MouseEvent):void{	
			isMouseDown = false;
			hasMoved = false;	
			//trace("mouse up: " + isCtrlDown);
			if (!isCtrlDown) setCursor("handOpen");
			//else this.addEventListener(Event.ENTER_FRAME, handleCrtlDownOEF, false, 0, true);
			try{
				if (this.markerManager.markerContainer.contains(selectionBox)){
					var neLatLon:LatLon = new LatLon(selectionBox.latlon.lat, mouseLatLon.lon);
					var swLatLon:LatLon = new LatLon(mouseLatLon.lat, selectionBox.latlon.lon);
					var bounds:BoundingBox = new BoundingBox(swLatLon, neLatLon);
					var event:MapEvent;
					if(isCtrlDown){
						event = new MapEvent(MapEvent.SELECTION_WITH_CTRL);
						event.bounds = bounds;
						dispatchEvent(event);
					}
				}
			}
			catch(e:Error){}
			try{
				if (selectionBox) {
					removeSelectionBox();
				}
			}
			catch(e:Error){};
		}	
		
		protected function handleCrtlDownOEF(p_evt:Event):void{
			trace("handleCrtlDownOEF");
		}
	
		
		
		protected function handleMouseMove(event:MouseEvent):void{	
			if(CursorManager.currentCursorID == 0) setCursor("handOpen");
			var tempPoint:Point = new Point(event.stageX-(this.mapWidth/2), event.stageY-(this.mapHeight/2));
			tempPoint = this.mapContainer.parent.parent.globalToLocal(tempPoint);
			var localPoint:Point = new Point(-tempPoint.x, -tempPoint.y);
			mouseLatLon = this.getXYToLatLon(localPoint);
			//trace("mouse move: " + [isCtrlDown, !hasMoved, isMouseDown]);	
			if (isCtrlDown && !hasMoved && isMouseDown){
				hasMoved = true;
				enableBuckets(false);
				addSelectionBox(mouseLatLon);	
				this.overlayContainer.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
				this.overlayContainer.removeEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown);
			}	
			//this is for tracking for out of bounds drag.
			if (getMapBounds().maxLat >= 85 && !draggingOutOfTopBounds){
				//trace("out of top bounds");
				initBounds = this.getMapBounds();
				draggingOutOfTopBounds = true;
				draggingOutOfBottomBounds = false;
			}			
			if (getMapBounds().minLat <= -85 && !draggingOutOfBottomBounds){
				//trace("out of bottom bounds");
				initBounds = this.getMapBounds();
				draggingOutOfBottomBounds = true;	
				draggingOutOfTopBounds = false;		
			}			
			if (getMapBounds().maxLon >= 180 && !draggingOutOfRightBounds){
				//trace("out of right bounds");
				initBounds = this.getMapBounds();
				draggingOutOfRightBounds = true;
				draggingOutOfLeftBounds = false;
			}			
			if (getMapBounds().minLon <= -180 && !draggingOutOfLeftBounds){
				//trace("out of left bounds");
				initBounds = this.getMapBounds();
				draggingOutOfRightBounds = false;	
				draggingOutOfLeftBounds = true;		
			}
		}
		
		
				
		/*****************************
		 * KEY EVENT HANDLERS
		 * ***************************/		
		protected function handleKeyDown(p_evt:KeyboardEvent):void{
			if (p_evt.ctrlKey){//command (mac) or ctrl (windows)
				this.removePanControl();
				isCtrlDown = true;
				hasMoved = false;
				setCursor("zoom");
				enableBuckets(true);
				this.overlayContainer.addEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove, false, 0, true);
				this.overlayContainer.addEventListener(MouseEvent.MOUSE_DOWN, handleMouseDown, false, 0, true);
			}
			else if (p_evt.shiftKey){	
			}
			else if (p_evt.keyCode == 66){ //keycode for b
			}
		}	
		protected function handleKeyUp(p_evt:KeyboardEvent):void{
			isCtrlDown = false;
			hasMoved = false;
			this.addPanControl();
			setCursor("handOpen");
			enableBuckets(false);			
			try{
				if (this.markerManager.markerContainer.contains(selectionBox)) removeSelectionBox();
			}catch(e:Error){}
		}
		
		
		
		
		/*****************************
		 * SELECTION BOX
		 * ***************************/		
		protected function addSelectionBox(p_latlon:LatLon):void{
			// for unknown reason the logic in handleMouseMove() is failing in Windows and this method is getting called multiple time during a drag
			try{if (selectionBox) return;}catch(e:Error){};
			selectionBox = new SelectionBox();
			selectionBox.latlon = p_latlon;
			selectionBox.addEventListener(MouseEvent.MOUSE_UP, handleMouseUp, false, 0, true);
			this.markerManager.addMarker(selectionBox);
		}		
		protected function removeSelectionBox():void{
			selectionBox.removeEventListener(MouseEvent.MOUSE_UP, handleMouseUp);
			selectionBox.stopHandleDrag();
			this.markerManager.removeMarker(selectionBox);
			selectionBox = null;
		}
		
		
		
		
		/*****************************
		 * BUCKET UTILITIES
		 * ***************************/		
		
		protected function enableBuckets(p_isEnabled:Boolean = true):void{
			bucketsAreEnabled = p_isEnabled;
			var len:uint = buckets.length;
			for (var i:uint = 0; i<len; i++){
				buckets[i].mouseEnabled = p_isEnabled;
			}
		}
		
		protected function zoomToBucket(p_evt:MouseEvent):void{
			isMouseDown = false;			
			this.setMapBounds(p_evt.target.boundingBox);
			var event:MapEvent = new MapEvent(MapEvent.BUCKET_CLICK);
			dispatchEvent(event);
			this.overlayContainer.removeEventListener(MouseEvent.MOUSE_MOVE, handleMouseMove);
		}
		
		protected function removeBuckets():void{			
			var len:uint = buckets.length;
			for (var i:uint = 0; i<len; i++){
				this.overlayManager.removeOverlay(buckets[i]);
			}
		}
		protected function removeGridLines():void{			
			var len:uint = gridLines.length;
			for (var i:uint = 0; i<len; i++){
				this.overlayManager.removeOverlay(gridLines[i]);
			}
		}
		
		
		
		
		
		/*****************************
		 * EVENT HANDLERS
		 * ***************************/	
		 		
		protected function handleStageLeave(p_evt:Event):void{
			handleMouseUp(new MouseEvent(MouseEvent.MOUSE_UP));
			setCursor("default");
		}
		
		protected function handleMapInitialize(event:YahooMapEvent):void{
			dispatchEvent(new MapEvent(MapEvent.MAP_INITIALIZE)); 
			stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyDown, false, 0, true);
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyUp, false, 0, true);
			stage.addEventListener(Event.MOUSE_LEAVE, handleStageLeave, false, 0, true);
			initBounds = this.getMapBounds();
		}
		
		protected function handleMapTypeChange(event:YahooMapEvent):void{
			var evt:MapEvent = new MapEvent(MapEvent.MAP_TYPE_CHANGED);
			evt.mapType = this.mapType;
			dispatchEvent(evt);
		}
		protected function handleDragStart(p_evt:YahooMapEvent):void{
			var event:MapEvent = new MapEvent(MapEvent.MAP_DRAG_START);
			//initBounds = this.getMapBounds();
			dispatchEvent(event);
		}
		protected function handleDragStop(p_evt:YahooMapEvent):void{
			
			//IF the map is dragged out of bounds it is snapped back
			var bounds:BoundingBox = this.getMapBounds();
			if (bounds.maxLon >= 180 || bounds.maxLat >=85 || bounds.minLat <= -85 || bounds.minLon <= -180){
				var newLat:Number = this.centerLatLon.lat;
				var newLon:Number = this.centerLatLon.lon;
				if (draggingOutOfTopBounds || draggingOutOfBottomBounds) newLat = initBounds.centerLatLon.lat;
				if (draggingOutOfRightBounds) newLon = 180 - (initBounds.lonSpan/2);
				else if (draggingOutOfLeftBounds) newLon = -180 + (initBounds.lonSpan/2);
				//trace([newLat,newLat]);
				this.centerLatLon = new LatLon(newLat, newLon);
				draggingOutOfTopBounds = false;
				draggingOutOfBottomBounds = false;				
				draggingOutOfRightBounds = false;
				draggingOutOfLeftBounds = false;
			} 
			
			
			var event:MapEvent = new MapEvent(MapEvent.MAP_DRAG_STOP);
			if (buckets.length > 0){
				event.gridBounds = getBucketResultBounds();
			}
			dispatchEvent(event);
		}
		protected function handleMapDoubleClick(p_evt:YahooMapEvent):void{
			dispatchEvent(new MapEvent(MapEvent.MAP_DOUBLE_CLICK));
		}
	}
}