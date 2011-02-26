package demos 
{
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import flash.ui.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	
	/**
	 * A simple controllable rigid car with shocks.
	 * INSTRUCTIONS: Use left/right or A/D to move the car back and forth.
	 * 
	 * @author Doug Koellmer
	 */
	public class RigidCar extends Demo
	{
		private var car:qb2Group;
		
		public function RigidCar() 
		{
			var utilPoint:amPoint2d = new amPoint2d(stageWidth / 2, stageHeight / 2);
			var wheelRadius:Number = 40;
			var bodyLength:Number = 120;
			var bodyHeight:Number = 40;
			var alteredFriction:Number = 2;
			var rampMajor:Number = 300, rampMinor:Number = 200, rampThickness:Number = 10;
			
			//--- Instantiate all the parts.
			car = new qb2Group();
			var wheel1:qb2CircleShape = qb2Stock.newCircleShape(utilPoint.clone().incX( -bodyLength / 2), wheelRadius, 1);
			var wheel2:qb2CircleShape = qb2Stock.newCircleShape(utilPoint.clone().incX( bodyLength / 2), wheelRadius, 1);
			var carBody:qb2PolygonShape = qb2Stock.newEllipseShape(utilPoint.clone().incY( -bodyLength / 2), new amVector2d(bodyLength/2 + 10, 0), bodyHeight, 18, 0, 2 * AM_PI, 2);
			wheel1.friction = wheel2.friction = alteredFriction;
			wheel1.angularDamping = wheel2.angularDamping = .1;
			
			//--- Connect the wheels to the car body with piston joints.
			var leftSpring:qb2PistonJoint = new qb2PistonJoint(carBody, wheel1, carBody.position.clone().incX( -bodyLength/2), wheel1.position);
			var rightSpring:qb2PistonJoint = new qb2PistonJoint(carBody, wheel2, carBody.position.clone().incX( bodyLength/2), wheel2.position);
			leftSpring.springK = rightSpring.springK = 40;
			leftSpring.springDamping = rightSpring.springDamping = .75;
			leftSpring.freeRotation = rightSpring.freeRotation = true; // this is like b2LineJoint, where the second object can spin freely.
			
			//--- Construct the car.
			car.addObject(carBody);
			car.addObject(wheel1);
			car.addObject(wheel2);
			car.addObject(leftSpring);
			car.addObject(rightSpring);
			this.addObject(car); // car is one, self-contained unit now.
			
			//--- Make a little ramp out of the inside of an elliptical arc.
			var ramp:qb2Body = qb2Stock.newEllipticalArcBody(new amPoint2d(stageWidth - rampMajor, stageHeight - rampMinor), new amVector2d( -rampMajor, 0), rampMinor, 12, AM_PI *.85, AM_PI * 1.5, rampThickness);
			ramp.position.y += rampThickness;
			ramp.friction = alteredFriction;
			this.addObject(ramp);
			
			//--- Make a keyboard, or make sure it exists.
			qb2Keyboard.makeSingleton(this.stage);
			
			car.addEventListener(qb2UpdateEvent.POST_UPDATE, updateCar);
		}
		
		private function updateCar(evt:qb2UpdateEvent):void
		{
			//--- Check which keys are down and adjust torque as necessary.
			var maxTorque:Number = 20;
			var torque:Number = 0;
			if ( qb2Keyboard.singleton.isDown(Keyboard.LEFT, Keyboard.A) )
				torque -= maxTorque;
			if ( qb2Keyboard.singleton.isDown(Keyboard.RIGHT, Keyboard.D) )
				torque += maxTorque;
	
			//--- Search through the car's objects to find the wheels (there are obviously better ways to do this).
			for (var i:int = 0; i < car.numObjects; i++) 
			{
				//--- Apply torque to the wheels.
				var object:qb2Object = car.getObjectAt(i);
				if ( object is qb2CircleShape)
				{
					(object as qb2CircleShape).applyTorque(torque);
				}
			}
		}
	}
}