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

package TopDown.objects 
{
	import As3Math.geo2d.amPoint2d;
	import flash.display.CapsStyle;
	import flash.display.Graphics;
	import QuickB2.objects.qb2Object;
	import QuickB2.stock.qb2Terrain;
	import TopDown.internals.tdInternalSkidEntry;
	
	import TopDown.td_friend;
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdTerrain extends qb2Terrain
	{
		public static const SKID_TYPE_ROLLING:uint = 1;
		public static const SKID_TYPE_SLIDING:uint = 2;
		
		public var rollingFrictionZMultiplier:Number = 1;
		
		public var slidingSkidColor:uint = 0x000000;
		public var rollingSkidColor:uint = 0x000000;
		
		public var slidingSkidAlpha:Number = .6;
		public var rollingSkidAlpha:Number = .6;
		
		public var skidDuration:Number = 2;
		
		public var drawSlidingSkids:Boolean = true;
		public var drawRollingSkids:Boolean = false;
		
		public function tdTerrain(ubiquitous:Boolean = false) 
		{
			_ubiquitous = ubiquitous;
		}
		
		public function get ubiquitous():Boolean
			{  return _ubiquitous;  }
		private var _ubiquitous:Boolean;
		
		public function addSkid(start:amPoint2d, end:amPoint2d, thickness:Number, type:uint):void
		{
			var entry:tdInternalSkidEntry = new tdInternalSkidEntry();
			entry.start = start;
			entry.end   = end;
			entry.thickness = thickness;
			entry.startTime = world.clock;
			entry.type = type;
			
			skidEntries.push(entry);
		}
		
		private var skidEntries:Vector.<tdInternalSkidEntry> = new Vector.<tdInternalSkidEntry>();
		
		public override function draw(graphics:Graphics):void
		{
			super.draw(graphics);
			
			drawSkids(graphics);
		}
		
		public override function drawDebug(graphics:Graphics):void
		{
			super.drawDebug(graphics);
			
			drawSkids(graphics);
		}
		
		public function drawSkids(graphics:Graphics):void
		{
			var time:Number = world.clock;
			
			for ( var i:int = 0; i < skidEntries.length; i++ )
			{
				var entry:tdInternalSkidEntry = skidEntries[i];
				var startAlpha:Number = entry.type == SKID_TYPE_SLIDING ? slidingSkidAlpha : rollingSkidAlpha;
				var color:uint = entry.type == SKID_TYPE_SLIDING ? slidingSkidColor : rollingSkidColor;
				
				if ( time - entry.startTime > skidDuration )
				{
					skidEntries.splice(i--, 1);
				}
				else
				{
					var alpha:Number = startAlpha * (1 - (time - entry.startTime) / skidDuration );
					graphics.lineStyle(entry.thickness, color, alpha, false, "normal", CapsStyle.NONE);
					//trace(entry.thickness, entry.color, alpha, entry.start, entry.end);
					graphics.moveTo(entry.start.x, entry.start.y);
					graphics.lineTo(entry.end.x, entry.end.y);
				}
			}
		}
		
		public override function clone():qb2Object
		{
			var cloned:tdTerrain = super.clone() as tdTerrain;
			
			cloned.rollingFrictionZMultiplier = this.rollingFrictionZMultiplier;
			cloned.rollingSkidColor = this.rollingSkidColor;
			cloned.slidingSkidColor = this.slidingSkidColor;
			cloned.slidingSkidAlpha = this.slidingSkidAlpha;
			cloned.rollingSkidAlpha = this.rollingSkidAlpha;
			cloned.skidDuration     = this.skidDuration;
			cloned._ubiquitous      = this._ubiquitous;
			
			return cloned;
		}
	}
}