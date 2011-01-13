/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package QuickB2.debugging 
{
	import com.bit101.components.*;
	import flash.display.DisplayObject;
	import flash.events.*;
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	import QuickB2.qb2_friend;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2DebugPanel extends Window
	{
		public static var rememberSettings:Boolean = true;
		
		qb2_friend static const DEFAULT_ALPHA:Number = .75;
		
		private var outlines:CheckBox, fills:CheckBox, verts:CheckBox, positions:CheckBox, centroids:CheckBox, bounds:CheckBox, boundCircles:CheckBox, joints:CheckBox;
		
		private var checkboxMap:Object =
		{
			outlines     : qb2DebugDrawSettings.DRAW_OUTLINES, 
			fills        : qb2DebugDrawSettings.DRAW_FILLS,
			verts        : qb2DebugDrawSettings.DRAW_VERTICES,
			positions    : qb2DebugDrawSettings.DRAW_POSITIONS,
			centroids    : qb2DebugDrawSettings.DRAW_CENTROIDS,
			bounds       : qb2DebugDrawSettings.DRAW_BOUND_BOXES,
			boundCircles  : qb2DebugDrawSettings.DRAW_BOUND_CIRCLES,
			joints       : qb2DebugDrawSettings.DRAW_JOINTS
		};
		
		private var objToString:Dictionary = new Dictionary();
		
		private var alphaSlider:VUISlider;
		
		private var boundBoxRange:HRangeSlider, centroidRange:HRangeSlider, boundCircleRange:HRangeSlider;
		
		private var fps:FPSMeter;
		private var polyCount:Label;
		private var circCount:Label;
		private var jointCount:Label;
		
		private var pausePlay:PushButton;
		
		private var polyStart:String  = "  POLYGONS";
		private var circStart:String  = "  CIRCLES";
		private var jointStart:String = "  JOINTS";
		
		public function qb2DebugPanel()
		{			
			this.title = "QuickB2 Debug Panel";
			this.hasMinimizeButton = true;
			this.draggable = true;
			this.grips.visible = true;
			this.alpha = DEFAULT_ALPHA;
			
			width = 150;  height = 415;
			
			const left:Number = 7;
			
			// FLAG CHECK BOXES
			var startY:Number = 35, incY:Number = 20;
			outlines = new CheckBox(this, left, startY, "Draw Lines", checkBoxChange);
			fills = new CheckBox(this, left, outlines.y+incY, "Draw Fills", checkBoxChange);
			verts = new CheckBox(this, left, fills.y+incY, "Draw Vertices", checkBoxChange);
			positions = new CheckBox(this, left, verts.y+incY, "Draw Positions", checkBoxChange);
			centroids = new CheckBox(this, left, positions.y + incY, "Draw Centroids", checkBoxChange);
			bounds = new CheckBox(this, left, centroids.y+incY, "Draw Bound Boxes", checkBoxChange);
			boundCircles = new CheckBox(this, left, bounds.y+incY, "Draw Bound Circles", checkBoxChange);
			joints = new CheckBox(this, left, boundCircles.y + incY, "Draw Joints", checkBoxChange);
			
			objToString[outlines] = "outlines";
			objToString[fills] = "fills";
			objToString[verts] = "verts";
			objToString[positions] = "positions";
			objToString[centroids] = "centroids";
			objToString[bounds] = "bounds";
			objToString[boundCircles] = "boundCircles";
			objToString[joints] = "joints";			
			
			// SLIDERS
			alphaSlider = new VUISlider(this, 110, 30, "Alpha", alphaChange);
			alphaSlider.labelPrecision = 2;
			alphaSlider.tick = .05;
			alphaSlider.height = 155;
			alphaSlider.maximum = 1;
			
			// RANGES
			const rangeX:Number = 15;
			startY = joints.y + 30;  incY = 40;
			boundBoxRange = new HRangeSlider(this, 0, startY);
			boundBoxRange.minimum = 0;
			boundBoxRange.maximum = 10;
			boundBoxRange.tick = 1;
			boundBoxRange.addEventListener(Event.CHANGE, rangeChange);
			var boundBoxRangeLabel:Label = new Label(this, 0, startY + 10, "Bound Box Depth");
			boundBoxRange.x = this.width / 2 - boundBoxRange.width / 2;
			boundBoxRangeLabel.x = this.width / 2 - boundBoxRangeLabel.width / 2;
		
			boundCircleRange = new HRangeSlider(this, 0, startY + incY);
			boundCircleRange.minimum = 0;
			boundCircleRange.maximum = 10;
			boundCircleRange.tick = 1;
			boundCircleRange.addEventListener(Event.CHANGE, rangeChange);
			var boundCircleRangeLabel:Label = new Label(this, 0, startY + incY + 10, "Bound Circle Depth");
			boundCircleRange.x = this.width / 2 - boundBoxRange.width / 2;
			boundCircleRangeLabel.x = this.width / 2 - boundBoxRangeLabel.width / 2;
			
			centroidRange = new HRangeSlider(this, 0, startY + incY*2);
			centroidRange.minimum = 0;
			centroidRange.maximum = 10;
			centroidRange.tick = 1;
			centroidRange.addEventListener(Event.CHANGE, rangeChange);
			var centroidRangeLabel:Label = new Label(this, 0, startY + incY*2 + 10, "Centroid Depth");
			centroidRange.x = this.width / 2 - centroidRange.width / 2;
			centroidRangeLabel.x = this.width / 2 - centroidRangeLabel.width / 2;
			
			var heightOffset:Number = -5;
			polyCount = new Label(this, left, centroidRangeLabel.y + centroidRangeLabel.height + 10, "0" + polyStart);
			circCount = new Label(this, left, polyCount.y + polyCount.height + heightOffset, "0" + circStart);
			jointCount = new Label(this, left, circCount.y + circCount.height + heightOffset, "0" + jointStart);
			fps = new FPSMeter(this,    left, 390, "FPS: ");
			//fps.y = this.height - fps.height;
			
			pausePlay = new PushButton(this, 0, 390, "Pause", buttonPushed);
			pausePlay.width *= .5;
			pausePlay.x = this.width - pausePlay.width - 5;
			
			addEventListener(Event.ADDED_TO_STAGE, added); // to start fps
			
			initSettings();
		}
		
		private function update(evt:Event):void
		{
			var numPolys:uint = 0, numCircles:uint = 0, numJoints:uint = 0;
			
			var worldDict:Dictionary = qb2World.worldDict;
			for (var key:* in worldDict)
			{
				var world:qb2World = worldDict[key];
				numPolys   += world.totalNumPolygons;
				numCircles += world.totalNumCircles;
				numJoints  += world.totalNumJoints;
			}
			
			polyCount.text  = numPolys + polyStart;
			circCount.text  = numCircles + circStart;
			jointCount.text = numJoints + jointStart;
			
			var data:Object = sharedData;
			data.windowX = this.x;
			data.windowY = this.y;
		}
		
		private function initSettings():void
		{
			if ( rememberSettings )
			{
				var data:Object = sharedData;
				
				//--- Set the shared data initially it looks like it hasn't been set before.
				if ( !data.hasOwnProperty("outlines") )
				{
					for ( var key:String in checkboxMap)
					{
						data[key] = qb2DebugDrawSettings.drawFlags & checkboxMap[key] ? true : false
					}
					
					data.boundBoxRangeLow     = qb2DebugDrawSettings.boundBoxStartDepth;
					data.boundBoxRangeHigh    = qb2DebugDrawSettings.boundBoxEndDepth;
					data.boundCircleRangeLow  = qb2DebugDrawSettings.boundCircleStartDepth;
					data.boundCircleRangeHigh = qb2DebugDrawSettings.boundCircleEndDepth;
					data.centroidRangeLow     = qb2DebugDrawSettings.centroidStartDepth;
					data.centroidRangeHigh    = qb2DebugDrawSettings.centroidEndDepth;
					
					data.alphaSliderValue     = .75;
					
					data.windowMinimized = false;
					data.windowX = data.windowY = 0;
				}
				
				//---- Set window settings based on shared properties.
				for ( key in checkboxMap)
				{
					manualSet(this[key], checkboxMap[key],      data[key]     == true);
				}
				
				boundBoxRange.lowValue     = data.boundBoxRangeLow;
				boundBoxRange.highValue    = data.boundBoxRangeHigh;
				boundCircleRange.lowValue  = data.boundCircleRangeLow;
				boundCircleRange.highValue = data.boundCircleRangeHigh;
				centroidRange.lowValue     = data.centroidRangeLow;
				centroidRange.highValue    = data.centroidRangeHigh;
				
				alphaSlider.value          = data.alphaSliderValue;
				
				this.minimized = data.windowMinimized == true;
				this.x = data.windowX;
				this.y = data.windowY;
			}
			else
			{
				for ( key in checkboxMap)
				{
					this[key].selected = qb2DebugDrawSettings.drawFlags & checkboxMap[key] ? true : false;
				}
				
				boundBoxRange.lowValue     = qb2DebugDrawSettings.boundBoxStartDepth;
				boundBoxRange.highValue    = qb2DebugDrawSettings.boundBoxEndDepth;
				
				boundCircleRange.lowValue  = qb2DebugDrawSettings.boundCircleStartDepth;
				boundCircleRange.highValue = qb2DebugDrawSettings.boundCircleEndDepth;
				
				centroidRange.lowValue  = qb2DebugDrawSettings.centroidStartDepth;
				centroidRange.highValue = qb2DebugDrawSettings.centroidEndDepth;
				
				alphaSlider.value = .75;
			}
			
			alphaChange(null);
		}
		
		private static function manualSet(checkBox:CheckBox, bit:uint, flag:Boolean):void
		{
			checkBox.selected = flag;
			if ( flag )
				qb2DebugDrawSettings.drawFlags |= bit;
			else
				qb2DebugDrawSettings.drawFlags &= ~bit;
		}
		
		private static function get sharedData():Object
			{  return SharedObject.getLocal("QuickB2DebugPanelSharedObject").data;  }
			
		private static function setSharedData(variable:String, value:*):void
		{
			if ( !rememberSettings )  return;
			
			sharedData[variable] = value;
		}
		
		public override function set minimized(value:Boolean):void
		{
			for (var i:int = 0; i < numChildren; i++) 
			{
				var child:DisplayObject = getChildAt(i);
				
				if ( child != grips && child != _minimizeButton && child != _titleLabel && child != _titleBar && child != _panel )
				{
					child.visible = !value;
				}
			}
			
			super.minimized = value;
			setSharedData("windowMinimized", value);
			
			if ( !minimized )
			{
				this.setChildIndex(_panel, 0);
			}
		}
		
		private function buttonPushed(evt:Event):void
		{
			var sum:int = 0;
			
			var dict:Dictionary = qb2World.worldDict;
			if ( pausePlay.label == "Pause" )
			{
				pausePlay.label = "Play";
				
				for (var key:* in dict )
				{
					dict[key].stop();
					sum++;
				}
			}
			else
			{
				pausePlay.label = "Pause";
				
				for (key in dict)
				{
					dict[key].start();
					sum++;
				}
			}
			
			trace("Number of worlds paused or played: " + sum);
		}
		
		private function added(evt:Event):void
		{
			fps.start();
			removeEventListener(Event.ADDED_TO_STAGE, added, false);
			addEventListener(Event.REMOVED_FROM_STAGE, removed, false, 0, true );
			addEventListener(Event.ENTER_FRAME, update, false, 0, true);
		}
		
		private function removed(evt:Event):void
		{
			fps.stop();
			removeEventListener(Event.REMOVED_FROM_STAGE, removed, false);
			addEventListener(Event.ADDED_TO_STAGE, added, false, 0, true);
			removeEventListener(Event.ENTER_FRAME, update);
		}
		
		private function checkBoxChange(evt:Event):void
		{
			var key:String = objToString[evt.currentTarget];
			
			if ( !key )  return;
			
			var flag:Boolean = evt.currentTarget.selected;
			var drawFlag:uint = checkboxMap[key] as uint;
			setSharedData(key, flag);
			
			if ( flag )
				qb2DebugDrawSettings.drawFlags |= drawFlag;
			else
				qb2DebugDrawSettings.drawFlags &= ~drawFlag;
		}
		
		private function alphaChange(evt:Event):void
		{
			qb2DebugDrawSettings.fillAlpha = qb2DebugDrawSettings.outlineAlpha = qb2DebugDrawSettings.boundBoxAlpha = qb2DebugDrawSettings.centroidAlpha = alphaSlider.value;
			setSharedData("alphaSliderValue", alphaSlider.value);
		}
		
		private function rangeChange(evt:Event):void
		{
			if ( evt.currentTarget == boundBoxRange )
			{
				qb2DebugDrawSettings.boundBoxStartDepth = boundBoxRange.lowValue;
				qb2DebugDrawSettings.boundBoxEndDepth   = boundBoxRange.highValue;
				
				setSharedData("boundBoxRangeLow", boundBoxRange.lowValue);
				setSharedData("boundBoxRangeHigh", boundBoxRange.highValue);
			}
			else if( evt.currentTarget == centroidRange )
			{
				qb2DebugDrawSettings.centroidStartDepth = centroidRange.lowValue;
				qb2DebugDrawSettings.centroidEndDepth   = centroidRange.highValue;
				
				setSharedData("centroidRangeLow", centroidRange.lowValue);
				setSharedData("centroidRangeHigh", centroidRange.highValue);
			}
			
			else if( evt.currentTarget == boundCircleRange )
			{
				qb2DebugDrawSettings.boundCircleStartDepth = boundCircleRange.lowValue;
				qb2DebugDrawSettings.boundCircleEndDepth   = boundCircleRange.highValue;
				
				setSharedData("boundCircleRangeLow", boundCircleRange.lowValue);
				setSharedData("boundCircleRangeHigh", boundCircleRange.highValue);
			}
		}
	}
}