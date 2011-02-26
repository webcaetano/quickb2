package demos 
{
	import As3Math.geo2d.amPoint2d;
	import flash.display.InteractiveObject;
	import flash.events.MouseEvent;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.events.qb2UpdateEvent;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2CircleShape;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * INSTRUCTIONS: Use your mouse to draw lines all around the place.
	 * NOTE: You can probably make this crash if you really want.
	 * ANOTHER NOTE: This is a pretty complicated demo, but I didn't really feel like commenting it.
	 * YET ANOTHER NOTE: This demo doesn't win any awards for efficiency, so don't take anything here as best practice.
	 * 
	 * @author Doug Koellmer
	 */
	public class Drawing extends Demo
	{
		private static const MIN_DISTANCE:Number = 50;
		private static const LINE_THICKNESS:Number = 10;

		private var currPolyline:qb2Body;
		
		public function Drawing() 
		{
			this.restitution = .5;
			
			var ballRadius:Number = 10;
			var numBalls:uint = 80;
			var center:amPoint2d = new amPoint2d(stage.stageWidth / 2, stage.stageHeight / 2);
			
			for (var j:int = 0; j < numBalls; j++) 
			{
				this.addObject(qb2Stock.newCircleShape(center.clone(), ballRadius, 1));
			}
			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, toggleDragging );
			addEventListener(qb2UpdateEvent.POST_UPDATE, updateLines);
		}
		
		private const pointStack:Vector.<amPoint2d> = new Vector.<amPoint2d>();
		
		private function updateLines(evt:qb2UpdateEvent):void
		{
			if ( !mouseDown )  return;
			
			var currPoint:amPoint2d = new amPoint2d(stage.mouseX, stage.mouseY);
			if ( currPoint.distanceTo(lastPoint) >= MIN_DISTANCE )
			{
				pointStack.push(currPoint);
				
				flushPolyline();
				
				lastPoint = currPoint;
			}
		}
		
		private function flushPolyline():void
		{
			if ( currPolyline )
			{
				removeObject(currPolyline);
			}
			
			if ( pointStack.length == 1 )
			{
				currPolyline = new qb2Body();
				currPolyline.position = pointStack[0];
				currPolyline.addObject(qb2Stock.newCircleShape(new amPoint2d(), LINE_THICKNESS / 2));
			}
			else
			{
				currPolyline = qb2Stock.newPolylineBody(pointStack, LINE_THICKNESS, 0, qb2Stock.CORNERS_ROUND, qb2Stock.CORNERS_ROUND);
			}
			
			addObject(currPolyline);
		}
		
		private var mouseDown:Boolean = false;
		private var lastPoint:amPoint2d = null;
		private var worldDragSprite:InteractiveObject = null;
		
		private function toggleDragging(evt:MouseEvent):void
		{
			var testPoint:amPoint2d = new amPoint2d(stage.mouseX, stage.mouseY);
			
			//--- Don't start drawing if this mouse down will invoke a drag of one of the circles.
			if ( evt.type == MouseEvent.MOUSE_DOWN )
			{
				for (var i:int = 0; i < numObjects; i++) 
				{
					var ithObject:qb2Object = getObjectAt(i);
					if ( !(ithObject is qb2CircleShape) )  continue;
					
					if ( (ithObject as qb2CircleShape).testPoint(testPoint) )
					{
						return;
					}
				}
			}
			
			lastPoint = testPoint;
			
			if ( evt.type == MouseEvent.MOUSE_DOWN )
			{
				mouseDown = true;
				stage.addEventListener(MouseEvent.MOUSE_UP, toggleDragging);
				
				pointStack.push(lastPoint);
				
				worldDragSprite = world.debugDragSource;
				world.debugDragSource = null;
			}
			else
			{
				if( pointStack.length == 1 )
					flushPolyline();
				
				mouseDown = false;
				stage.removeEventListener(MouseEvent.MOUSE_UP, toggleDragging);
				
				lastPoint = null;
				pointStack.length = 0;
				currPolyline = null;
				
				world.debugDragSource = worldDragSprite;
			}
		}
		
		protected override function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				addEventListener(qb2UpdateEvent.POST_UPDATE, updateLines);
				stage.addEventListener(MouseEvent.MOUSE_DOWN, toggleDragging);
			}
			else
			{
				removeEventListener(qb2UpdateEvent.POST_UPDATE, updateLines);
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, toggleDragging);
				
				if ( worldDragSprite )
					evt.ancestor.world.debugDragSource = worldDragSprite;
			}
		}
		
	}

}