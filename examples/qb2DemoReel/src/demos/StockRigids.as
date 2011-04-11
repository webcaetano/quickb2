package demos
{
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import QuickB2.effects.qb2GravityField;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	
	/**
	 * QuickB2 has a good amount of built-in support for making common geometric primitives and composites thereof.
	 * This example shows off qb2Stock's library, and also the basics of how you can create some composite objects.
	 * INSTRUCTIONS: Try throwing some objects into the grey left rectangle and see what happens.
	 * 
	 * @author Doug Koellmer
	 */
	public class StockRigids extends Demo
	{
		public function StockRigids()
		{
			//--- Some numbers to help lay things out on something of a grid.
			var numAcross:Number = 6, numDown:Number = 4;
			var incX:Number = stageWidth / (numAcross+1);
			var currX:Number = incX;
			var incY:Number = stageHeight / (numDown + 1);
			var currY:Number = incY;
			
			//--- Simple shapes can be added directly to the world...no bodies needed.
			//--- Notice how non-convex cases are handled transparently.
			addObject(qb2Stock.newCircleShape(new amPoint2d(currX, currY), 40, 1));
			currX += incX;
			addObject(qb2Stock.newIsoTriShape(new amPoint2d(currX, currY + 25), 50, 100, 1));
			currX += incX;
			addObject(qb2Stock.newPolygonShape(Vector.<amPoint2d>([new amPoint2d(currX- 25, currY), new amPoint2d(currX - 10, currY-40), new amPoint2d(currX + 30,currY - 20), new amPoint2d(currX + 25, currY + 10), new amPoint2d(currX, currY-10)]), null, 1));
			currX += incX;
			addObject(qb2Stock.newRectShape(new amPoint2d(currX, currY), 60, 40, 1, AM_PI / 3));
			currX += incX;
			addObject(qb2Stock.newRegularPolygonShape(new amPoint2d(currX, currY), 40, 12, 1));
			currX += incX;
			addObject(qb2Stock.newEllipseShape(new amPoint2d(currX, currY), new amVector2d( -50, -50), 30, 15, 0, AM_PI * 1.55, 1));
			
			currX = incX;
			currY += incY;
			
			//--- Sometimes it's hard or inefficient to make something with just one shape, so bodies are used to wrap multiple shapes.
			//--- The line in this case is the same as the pill, but with a different api call.
			addObject(qb2Stock.newPillBody(new amPoint2d(currX, currY), 100, 30, 1, AM_PI / 2));
			currX += incX;
			addObject(qb2Stock.newRoundedRectBody(new amPoint2d(currX, currY), 60, 80, 10, 1));
			currX += incX;
			addObject(qb2Stock.newLineBody(new amPoint2d(currX - 30, currY + 30), new amPoint2d(currX + 30, currY - 10), 10, 1, qb2Stock.ENDS_ROUND));
			currX += incX;
			addObject(qb2Stock.newEllipticalArcBody(new amPoint2d(currX, currY), new amVector2d(0, -50), 30, 12, 0, AM_PI * 2, 10, 1, qb2Stock.CORNERS_SHARP));
			(lastObject() as qb2Tangible).isBullet = true; // make the ellipse a bullet so that things can't tunnel through its walls.
			addObject(qb2Stock.newCircleShape(new amPoint2d(currX, currY), 10, 1)); // trap a small circle inside.
			currX += incX;
			addObject(qb2Stock.newPolylineBody(Vector.<amPoint2d>([new amPoint2d(currX-30, currY+30), new amPoint2d(currX +30, currY - 30), new amPoint2d(currX -30, currY-30), new amPoint2d(currX+30, currY+30)]), 15, 1, qb2Stock.CORNERS_SHARP, qb2Stock.ENDS_ROUND));
			currX += incX;
			addObject(qb2Stock.newPolylineBody(Vector.<amPoint2d>([new amPoint2d(currX-30, currY+30), new amPoint2d(currX +30, currY - 30), new amPoint2d(currX -30, currY-30), new amPoint2d(currX+30, currY+30)]), 15, 1, qb2Stock.CORNERS_ROUND, qb2Stock.ENDS_ROUND));
			
			currX = incX;
			currY += incY;
			
			//--- You can even wrap bodies within bodies, or bodies within bodies within bodies, or...you get the idea.
			var twoRoundRects:qb2Body = new qb2Body();
			twoRoundRects.position.set(currX, currY);
			twoRoundRects.addObject(qb2Stock.newRoundedRectBody(new amPoint2d(-25, 0), 50, 100, 10, 1));
			twoRoundRects.addObject(qb2Stock.newRoundedRectBody(new amPoint2d(50, 0), 50, 100, 10, 1, AM_PI / 2));
			twoRoundRects.scaleBy(.75, .75, twoRoundRects.position); // shrink this guy a little so he fits better in the layout.
			addObject(twoRoundRects);
			
			currX += incX;
			
			//--- Here's a really inefficient object, demonstrating the clone method.
			var numArms:Number = 8;
			var starBody:qb2Body = new qb2Body();
			starBody.position.set(currX, currY);
			var initialArm:qb2Body = qb2Stock.newPillBody(new amPoint2d(), 75, 10);
			starBody.addObject(initialArm);
			for (var i:int = 1; i < numArms; i++) 
			{
				var clone:qb2Body = initialArm.clone() as qb2Body;
				clone.rotateBy(i * ((AM_PI) / numArms));
				starBody.addObject(clone);
			}
			starBody.mass = 1;
			addObject(starBody);
			
			//--- .5 seconds after touching this sensor, an object will get shot away randomly.
			//--- If it's a body, it gets broken up into its constituent parts.
			var tripSensor:qb2TripSensor = qb2Stock.newRectSensor(new amPoint2d(stage.stageWidth / 2, stage.stageHeight - incX / 2 ), stage.stageWidth/2, incX / 2, 0);
			tripSensor.tripTime = .5;
			tripSensor.addEventListener(qb2TripSensorEvent.SENSOR_TRIPPED, tripped);
			addObjectAt(tripSensor, 0); // makes the sensor get drawn on the bottom z-wise.
		}
		
		private function tripped(evt:qb2TripSensorEvent):void
		{
			var tangible:qb2Tangible = evt.visitingObject;
			
			//--- Apply a random impulse, like a bat hitting the object.
			var impulseVec:amVector2d = new amVector2d(Math.random()*2-1, Math.random()*2-1);
			tangible.applyImpulse(tangible.centerOfMass, impulseVec.scaleBy(tangible.mass * 25));
			
			//--- Explode all children of a container up a level.  Not explode in the kabloom sense, but in the group operation sense.
			if ( tangible is qb2ObjectContainer )
			{
				//--- Turn off bullet mode on that ellipse so its sub-objects don't suck up CPU needlessly.
				if ( tangible.isBullet )
					tangible.isBullet = false;
				
				(tangible as qb2ObjectContainer).explode();
			}
		}
	}
}