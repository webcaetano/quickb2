package demos 
{
	import As3Math.geo2d.*;
	import QuickB2.events.*;
	import QuickB2.misc.qb2Keyboard;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;

	/**
	 * Here are some psuedo-soft bodies, compared to their rigid counterparts.
	 * 
	 * @author Doug Koellmer
	 */
	public class StockSofts extends Demo
	{
		public function StockSofts() 
		{
			//--- Some variables controlling the layout.
			var numAcross:Number = 5, numDown:Number = 4;
			var incX:Number = stageWidth / (numAcross+1);
			var currX:Number = incX;
			var yPos:Number = stageHeight/2;
			var circleRadius:Number = 40, rectWidth:Number = 100, rectHeight:Number = 60;
			
			//--- Make a rigid then soft circle.
			addObject(qb2Stock.newCircleShape(new amPoint2d(currX, yPos), circleRadius, 1));
			currX += incX;
			var jelloCircle:qb2SoftPoly = new qb2SoftPoly();
			jelloCircle.setAsCircle(new amPoint2d(currX, yPos), circleRadius, 16, 1, -1);
			addObject(jelloCircle);
			currX += incX;
			
			//--- Now do the same with rectangles.
			addObject(qb2Stock.newRectShape(new amPoint2d(currX, yPos), rectWidth, rectHeight, 1));
			currX += incX;
			var jelloRect:qb2SoftPoly = new qb2SoftPoly();
			jelloRect.setAsRect(new amPoint2d(currX, yPos), rectWidth, rectHeight, 4, 1, -2);
			addObject(jelloRect);
			currX += incX;
			
			//--- Add a cool little star.  Make this guy a little springier and bouncier.
			var jelloStar:qb2SoftPoly = new qb2SoftPoly();
			jelloStar.setAsStar(new amPoint2d(currX, yPos), 50, 25, 5, 2, 1, -3);
			jelloStar.springK = 10;
			jelloStar.restitution = .5;
			addObject(jelloStar);
		}
		
		//--- Jello stuff can tweak out if it doesn't have a small enough timestep.
		private var saveMaxTimeStep:Number;
		protected override function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				saveMaxTimeStep = world.maximumRealtimeStep;
				world.maximumRealtimeStep = 1.0 / 50.0;
			}
			else
			{
				evt.ancestor.world.maximumRealtimeStep = saveMaxTimeStep; // don't have access to world anymore here, so have to go through event property.
			}
		}
	}
}