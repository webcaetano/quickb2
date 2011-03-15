package demos 
{
	import As3Math.consts.AM_PI;
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amPolygon2d;
	import flash.display.Bitmap;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.events.qb2UpdateEvent;
	import QuickB2.objects.tangibles.qb2PolygonShape;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * INSTRUCTIONS: Drag the vertices around to morph the polygon in real time.
	 * NOTE: This demo won't allow you to create self-intersecting polygons...hopefully this can be addressed in a future release.
	 * 
	 * @author Doug Koellmer
	 */
	public class Cup extends Demo
	{		
		private var drags:Vector.<DragSprite>;
		private var currDrag:DragSprite;
		private var cup:qb2PolygonShape;
		
		public function Cup() 
		{
			//--- Layout variables for the cup and balls.
			var complexity:uint = 10;
			var cupRadius:Number = 150;
			var cupThickness:Number = 25;
			var ballRadius:Number = 10;
			var numBalls:uint = 80;
			var center:amPoint2d = new amPoint2d(stage.stageWidth / 2, stage.stageHeight / 2);
			
			//--- Lay out the vertices for a cup-shaped polygon, and add drag points
			//--- so the user can change the shape of the cup in real time.
			var verts:Vector.<amPoint2d> = new Vector.<amPoint2d>(complexity * 2, true);
			drags = new Vector.<DragSprite>(complexity * 2, true);
			var rotPoint1:amPoint2d = center.clone().incX(cupRadius);
			var rotPoint2:amPoint2d = center.clone().incX( -cupRadius - cupThickness);
			var inc:Number = AM_PI / ((complexity-1) as Number);
			for (var i:int = 0; i < complexity; i++) 
			{
				verts[i] = rotPoint1.rotatedBy(inc * i, center);
				verts[i + complexity] = rotPoint2.rotatedBy( -inc * i, center);
				
				drags[i] = new DragSprite(verts[i].x, verts[i].y, i);
				drags[i +complexity] = new DragSprite(verts[i + complexity].x, verts[i + complexity].y, i + complexity);
				
				drags[i].addEventListener(MouseEvent.MOUSE_DOWN, dragEvent);
				
				(actor as Sprite).addChild(drags[i]);
				stage.addChild(drags[i+complexity]);
			}
			
			//--- Create and add the cup to the demo.
			cup = new qb2PolygonShape();
			cup.set(verts, center);
			addObject(cup);
			
			//--- Add a bunch of balls.
			for (var j:int = 0; j < numBalls; j++) 
			{
				this.addObject(qb2Stock.newCircleShape(center.clone(), ballRadius, 1));
			}
			
			this.addEventListener(qb2UpdateEvent.POST_UPDATE, updateStuff);
		}
		
		private function dragEvent(evt:MouseEvent):void
		{			
			if ( evt.type == MouseEvent.MOUSE_DOWN )
			{
				currDrag = evt.target as DragSprite;
				currDrag.parent.setChildIndex(currDrag, currDrag.parent.numChildren - 1);
				
				//--- Make it so balls don't get accidentally dragged here.
				worldDragSprite = world.debugDragSource;
				world.debugDragSource = null;
				
				stage.addEventListener(MouseEvent.MOUSE_UP, dragEvent);
			}
			else if (currDrag )
			{
				//--- Restore dragging to the world.
				world.debugDragSource = worldDragSprite;
				
				stage.removeEventListener(MouseEvent.MOUSE_UP, dragEvent);
				currDrag = null;
			}
		}
		
		private var worldDragSprite:InteractiveObject;
		
		private function updateStuff(evt:qb2UpdateEvent):void
		{
			//--- Match the position of a vertex on the cup to the sprite being dragged.
			if ( currDrag )
			{
				var proposedPoint:amPoint2d = new amPoint2d(stage.mouseX, stage.mouseY);
				
				//--- Get a polygon representation with which to test self-intersection.
				var polygon:amPolygon2d = cup.asGeoPolygon();
				var ithVertex:amPoint2d = polygon.getVertexAt(currDrag.index);
				ithVertex.copy(proposedPoint);
				
				//--- Only change the cup if it doesn't intersect itself.  Self-intersecting polygons aren't handled well
				//--- by QuickB2.  This is on the TODO list, but it's a pretty tricky case to handle as self-intersecting
				//--- polygons aren't well-defined in many cases, as to where the "meat" of a polygon is and isn't.
				if ( !polygon.selfIntersects )
				{
					currDrag.x = proposedPoint.x;
					currDrag.y = proposedPoint.y;
					
					var cupVertex:amPoint2d = cup.getVertexAt(currDrag.index);
					cupVertex.copy(proposedPoint);
				}
			}
		}
		
		/// Clean up listeners.
		protected override function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				for (var i:int = 0; i < drags.length; i++) 
				{
					drags[i].addEventListener(MouseEvent.MOUSE_DOWN, dragEvent);
					stage.addChild(drags[i]);
				}
				addEventListener(qb2UpdateEvent.POST_UPDATE, updateStuff);
			}
			else
			{
				for ( i = 0; i < drags.length; i++) 
				{
					drags[i].removeEventListener(MouseEvent.MOUSE_DOWN, dragEvent);
					stage.removeChild(drags[i]);
				}
				removeEventListener(qb2UpdateEvent.POST_UPDATE, updateStuff);
				
				if ( worldDragSprite )
					evt.ancestor.world.debugDragSource = worldDragSprite;
			}
		}
	}
}

import flash.display.Bitmap;
import flash.display.Sprite;

/// Just a sprite for dragging.
class DragSprite extends Sprite
{
	[Embed(source='../../lib/pan_cursor.gif')]
	private static const PanCursor:Class;
	
	private var _index:uint;
		
	public function DragSprite(initX:Number, initY:Number, index:uint)
	{
		var img:Bitmap = new PanCursor();
		addChild(img);
		img.x = -img.width / 2;
		img.y = -img.height / 2;
		this.x = initX;
		this.y = initY;
		_index = index;
		
		this.buttonMode = true;
	}
	
	public function get index():uint
		{  return _index;  }
}