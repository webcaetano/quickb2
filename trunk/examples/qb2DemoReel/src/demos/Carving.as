package demos 
{
	import As3Math.general.amUpdateEvent;
	import As3Math.geo2d.amLine2d;
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import com.greensock.loading.core.DisplayObjectLoader;
	import com.greensock.loading.LoaderStatus;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import QuickB2.events.qb2ContactEvent;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.misc.qb2Mouse;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2PolygonShape;
	import QuickB2.objects.tangibles.qb2Tangible;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * How to use the slice function to add delicious destruction to your project.
	 * 
	 * @author Doug Koellmer
	 */
	public class Carving extends Demo
	{
		private static var mouse:qb2Mouse;
		
		private var crosshairs:Sprite = new Crosshairs();
		private var stone:qb2Body = new qb2Body();
		
		public function Carving() 
		{
			mouse = mouse ? mouse : new qb2Mouse(stage);
			
			stone.addObject(qb2Stock.newRectShape(new amPoint2d, stageWidth / 4, stageHeight / 4));
			//stone.mass = 1;
			stone.position.set(stageWidth / 2, stageHeight / 2);
			addObject(stone);
			
			var poly:qb2PolygonShape = stone.lastObject() as qb2PolygonShape;
			poly.insertVertexAt(1, new amPoint2d( -stageWidth / 16, -stageHeight / 8), new amPoint2d(0, -stageHeight / 4), new amPoint2d(stageWidth / 16, -stageHeight / 8));
			poly.getVertexAt(0).incY( -stageHeight / 8);
			poly.getVertexAt(4).incY( -stageHeight / 8);
			
			var stoneClone:qb2Body = stone.clone() as qb2Body;
			stoneClone.translateBy(new amVector2d( -200, -100));
			//stoneClone.mass = 1;
			//addObject(stoneClone);
			
			addObject(qb2Stock.newCircleBody(new amPoint2d(100, 100), 50, 0));
		}
		
		protected override function update():void
		{
			super.update();
			
			updateCrosshairs();
			
			//--- Make this one demo's code non-selectable, cause it's just annoying.
			CodeBlocks.singleton.currentBlock.editable = false;
			CodeBlocks.singleton.currentBlock.selectable = false;
		}
		
		public override function drawDebug(graphics:Graphics):void
		{
			super.drawDebug(graphics);
			
			if ( _dragging )
			{
				graphics.lineStyle(.1, 0, .75);
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
		
		private const CROSSHAIRS_LEAD_MULT:Number = 1;
		
		private function updateCrosshairs():void
		{
			if ( _dragging )
			{
				_endDrag.x = _startDrag.x + (Main.singleton.mouseX - _startDrag.x) * CROSSHAIRS_LEAD_MULT;
				_endDrag.y = _startDrag.y + (Main.singleton.mouseY - _startDrag.y) * CROSSHAIRS_LEAD_MULT;
				crosshairs.x = _endDrag.x;
				crosshairs.y = _endDrag.y;
			}
			else
			{
				crosshairs.x = Main.singleton.mouseX;
				crosshairs.y = Main.singleton.mouseY;
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
				_startDrag.set(Main.singleton.mouseX, Main.singleton.mouseY);
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
					var pieces:Vector.<qb2Tangible> = slice(sliceLine, hitPoints);
					
					if ( pieces )
					{
						for (var i:int = 0; i < pieces.length; i++) 
						{
							pieces[i].density = 1;
							pieces[i].isSliceable = false;
						}
					}
					
					var pulse:LaserPulse = new LaserPulse();
					trace("num po", hitPoints.length);
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
			}
			else
			{
				Mouse.show();
				stage.removeChild(crosshairs);
				mouse.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
				mouse.removeEventListener(MouseEvent.MOUSE_UP,   mouseEvent);
				stage.removeEventListener(Event.MOUSE_LEAVE,     mouseEvent);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseEvent);
			}
		}
	}
}

import As3Math.geo2d.amPoint2d;
import flash.display.Graphics;
import flash.display.Sprite;

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

class LaserPulse
{
	public var state:Number = 5;
	public var points:Vector.<amPoint2d>;
	private static const BASE_COLOR:uint = 0xff0000;
	
	public function draw(graphics:Graphics):void
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
				graphics.lineStyle(state, BASE_COLOR);
			}
			else
			{
				graphics.lineStyle(.5, 0);
			}
			
			graphics.moveTo(beg.x, beg.y);
			graphics.lineTo(end.x, end.y);
		}
		
		state -= .25;
	}
}