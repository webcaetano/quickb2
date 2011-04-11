package demos 
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.events.*;
	import flash.ui.*;
	import flash.utils.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import surrender.srGraphics2d;
	
	/**
	 * How to use the slice function to add delicious destruction to your project.
	 * Most of this demo is dedicated to crosshair click-drag interaction and graphics, and making smaller pieces fall off of larger pieces.
	 * The actual qb2Tangible::slice() function itself is very simple to use.
	 * 
	 * @author Doug Koellmer
	 */
	public class Carving extends Demo
	{
		private static var mouse:qb2Mouse;
		
		private var crosshairs:Sprite = new Crosshairs();
		
		private var circleCarving:qb2Body = new qb2Body();
		private var rectCarving:qb2Body   = new qb2Body();
		private var carvingBlocks:qb2Group = new qb2Group();
		
		public function Carving() 
		{
			mouse = mouse ? mouse : new qb2Mouse(stage);
			
			//--- Start off with a rectangle and insert a bunch of vertices to make parapets.
			rectCarving.addObject(qb2Stock.newRectShape(new amPoint2d(), stageWidth / 4, stageHeight / 4));
			rectCarving.position.set(stageWidth *.75, stageHeight / 2);
			var parHeight:Number = -stageHeight / 4 - 20;
			var normalHeight:Number = -stageHeight / 8;
			var inc:Number = stageWidth / 4 / 5;
			var left:Number = -stageWidth / 8;
			var poly:qb2PolygonShape = rectCarving.lastObject() as qb2PolygonShape;
			poly.getVertexAt(0).y = parHeight
			poly.getVertexAt(1).y = parHeight;
			poly.insertVertexAt(1,
				new amPoint2d(left + inc, parHeight),
				new amPoint2d(left+inc, normalHeight),
				new amPoint2d(left+inc*2, normalHeight),
				new amPoint2d(left+inc*2, parHeight),
				new amPoint2d(left+inc*3, parHeight),
				new amPoint2d(left+inc*3, normalHeight),
				new amPoint2d(left+inc*4, normalHeight),
				new amPoint2d(left+inc * 4, parHeight)
			);
			rectCarving.position.y += 20;
			rectCarving.position.x -= 30;
				
			//--- Make a circle to slice...this will get decomposed to polygons automatically since partial arcs aren't supported.
			circleCarving.position.set(stageWidth/4, stageHeight/2);
			var circleShape:qb2CircleShape = qb2Stock.newCircleShape(new amPoint2d(), stageWidth / 8, 0);
			circleCarving.addObject(circleShape);
			
			//--- 'carvingBlocks' will be the object that's sliced.
			carvingBlocks.addObject(rectCarving);
			carvingBlocks.addObject(circleCarving);
			addObject(carvingBlocks);
		}
		
		private const CROSSHAIRS_LEAD_MULT:Number = 1;
		
		private function updateCrosshairs(evt:Event = null):void
		{
			if ( _dragging )
			{
				_endDrag.x = _startDrag.x + (stage.mouseX - _startDrag.x) * CROSSHAIRS_LEAD_MULT;
				_endDrag.y = _startDrag.y + (stage.mouseY - _startDrag.y) * CROSSHAIRS_LEAD_MULT;
				crosshairs.x = _endDrag.x;
				crosshairs.y = _endDrag.y;
			}
			else
			{
				crosshairs.x = stage.mouseX;
				crosshairs.y = stage.mouseY;
			}
			
			var graphics:srGraphics2d = world.debugDrawGraphics;
			if ( !world.running )
			{
				graphics.clear();
				drawDebug(graphics);
			}
			if ( _dragging )
			{
				graphics.setLineStyle(.1, 0, .75);
				graphics.moveTo(_startDrag.x, _startDrag.y);
				graphics.lineTo(_endDrag.x, _endDrag.y);
			}
			
			for (var i:int = 0; i < _pulses.length; i++) 
			{
				var pulse:LaserPulse = _pulses[i];
				
				pulse.draw(graphics);
				
				if ( pulse.state == 0 )
				{
					_pulses.splice(i--, 1);
				}
			}
		}
		
		private var _dragging:Boolean = false;
		private var _startDrag:amPoint2d = new amPoint2d();
		private var _endDrag:amPoint2d = new amPoint2d();
		private var _pulses:Vector.<LaserPulse> = new Vector.<LaserPulse>();
		
		private function mouseEvent(evt:Event):void
		{
			if ( evt.type == MouseEvent.MOUSE_DOWN )
			{
				_dragging = true;
				_startDrag.set(stage.mouseX, stage.mouseY);
				_endDrag.copy(_startDrag);
			}
			else if( evt.type == MouseEvent.MOUSE_UP )
			{
				updateCrosshairs();
				
				if ( !_endDrag.equals(_startDrag, .001) )
				{
					var sliceLine:amLine2d = new amLine2d();
					sliceLine.point1 = _startDrag;
					sliceLine.point2 = _endDrag;
					var hitPoints:Vector.<amPoint2d> = new Vector.<amPoint2d>();
					
					var pieces:Vector.<qb2Tangible> = carvingBlocks.slice(sliceLine, hitPoints);
					
					if ( pieces )
					{					
						var pieceDict:Dictionary = new Dictionary(true);
						for (var i:int = 0; i < pieces.length; i++) 
						{
							var ithPiece:qb2Tangible = pieces[i];
							pieceDict[ithPiece.userData] = pieceDict[ithPiece.userData] ? pieceDict[ithPiece.userData] : ithPiece.userData is qb2CircleShape ? [] : [ithPiece.userData];
							pieceDict[ithPiece.userData].push(ithPiece);
						}
						
						for ( var key:* in pieceDict )
						{
							var newPieces:Array = pieceDict[key];
							
							var largestArea:Number = 0;
							var largestPiece:qb2Tangible = null;
							
							for (var j:int = 0; j < newPieces.length; j++)
							{
								var item:qb2Tangible = newPieces[j];
								var itemArea:Number = item.surfaceArea;
								
								if ( !largestPiece || item.surfaceArea > largestArea)
								{
									largestPiece = item;
									largestArea = item.surfaceArea;
								}
							}
							
							for ( j = 0; j < newPieces.length; j++) 
							{
								item = newPieces[j];
								if ( item != largestPiece )
								{
									item.density = 1; // make this piece fall off the largest piece, which remains static.
									
									item.turnSliceFlagOff(qb2_sliceFlags.IS_SLICEABLE); // make it so this object can't be sliced anymore.
								}
								else
								{
									if ( item.parent && !item.isDescendantOf(carvingBlocks) )
									{
										item.removeFromParent();
										carvingBlocks.addObject(item);
									}
								}
							}
						}
					}
					
					var pulse:LaserPulse = new LaserPulse();
					pulse.points = hitPoints;
					_pulses.push(pulse);
				}
				
				_dragging = false;
			}
			else if( evt.type == MouseEvent.MOUSE_MOVE )
			{
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
				stage.addEventListener(Event.MOUSE_LEAVE,        mouseEvent);
				
				crosshairs.visible = true;
				Mouse.hide();
			}
			else if ( evt.type == Event.MOUSE_LEAVE )
			{
				stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
				stage.removeEventListener(Event.MOUSE_LEAVE,  mouseEvent);
				
				crosshairs.visible = false;
				Mouse.show();
			}
		}
		
		protected override function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				Mouse.hide();
				updateCrosshairs();
				stage.addChild(crosshairs);
				mouse.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
				mouse.addEventListener(MouseEvent.MOUSE_UP,   mouseEvent);
				stage.addEventListener(Event.MOUSE_LEAVE,     mouseEvent);
				
				stage.addEventListener(Event.ENTER_FRAME, updateCrosshairs);
			}
			else
			{
				Mouse.show();
				stage.removeChild(crosshairs);
				mouse.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
				mouse.removeEventListener(MouseEvent.MOUSE_UP,   mouseEvent);
				stage.removeEventListener(Event.MOUSE_LEAVE,     mouseEvent);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
				
				stage.removeEventListener(Event.ENTER_FRAME, updateCrosshairs);
			}
		}
	}
}

import As3Math.geo2d.*;
import flash.display.*;
import surrender.srGraphics2d;
import surrender.srIDrawable2d;

class Crosshairs extends Sprite
{
	private static const SIZE:Number = 30;
	private static const INNER:Number = 2;
	
	public function Crosshairs()
	{
		graphics.lineStyle(2, 0xff0000, .75);
		graphics.drawCircle(0, 0, SIZE / 2);
		graphics.moveTo( -SIZE, 0);
		graphics.lineTo( -INNER, 0);
		graphics.moveTo( SIZE, 0);
		graphics.lineTo(INNER, 0);
		graphics.moveTo(0, -SIZE);
		graphics.lineTo(0, -INNER);
		graphics.moveTo(0, SIZE);
		graphics.lineTo(0, INNER);
	}
}

class LaserPulse implements srIDrawable2d
{
	public var state:Number = 4;
	public var points:Vector.<amPoint2d>;
	private static const BASE_COLOR:uint = 0xff0000;
	
	public function draw(graphics:srGraphics2d):void
	{
		var mode:int = 0;
		
		for (var i:int = 0; i < points.length-1; i++) 
		{
			var beg:amPoint2d = points[i];
			var end:amPoint2d = points[i + 1];
			
			if ( beg.userData is int )
			{
				mode = beg.userData;
			}
			else if ( beg.userData == "incoming" )
			{
				mode++;
			}
			else if( beg.userData == "outgoing" )
			{
				mode--;
			}
			
			
			if ( mode == 0 )
			{
				graphics.setLineStyle(state, BASE_COLOR, .75);
			}
			else
			{
				graphics.setLineStyle(.5, 0);
			}
			
			graphics.moveTo(beg.x, beg.y);
			graphics.lineTo(end.x, end.y);
		}
		
		state -= .25;
	}
}