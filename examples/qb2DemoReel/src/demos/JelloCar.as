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
	 * A simple controllable jello car.
	 * INSTRUCTIONS: Use left/right or A/D to move the car back and forth.
	 * 
	 * @author Doug Koellmer
	 */
	public class JelloCar extends Demo
	{
		private var car:qb2Group;
		
		public function JelloCar() 
		{
			//--- Some layout variables.
			var utilPoint:amPoint2d = new amPoint2d(stageWidth / 2, stageHeight / 2);
			var wheelRadius:Number = 40;
			var bodyLength:Number = 100;
			var bodyHeight:Number = 40;
			var alteredFriction:Number = 2;
			var rampMajor:Number = 300, rampMinor:Number = 200, rampThickness:Number = 10;
			
			//--- Instantiate all the parts.
			car = new qb2Group();
			var wheel1:qb2SoftPoly = new qb2SoftPoly();
			var wheel2:qb2SoftPoly = new qb2SoftPoly();
			var carBody:qb2SoftPoly = new qb2SoftPoly();
			
			//--- Fill out the parts.
			wheel1.setAsCircle(utilPoint.clone().incX( -bodyLength / 2), wheelRadius, 12, 1, -1);
			wheel2.setAsCircle(utilPoint.clone().incX( bodyLength / 2), wheelRadius, 12, 1, -1);
			carBody.setAsRect(utilPoint.clone(), bodyLength, bodyHeight, 3, 1, -1);
			wheel1.friction = wheel2.friction = alteredFriction; // give the wheels a little traction.
			
			//--- Attach the first wheel to the left side of the jello rectangle.
			//--- Attach two rigids across from each other on the wheel so it spins symmetrically.
			//--- The piston joint isn't really doing any pistoning, but just providing shocks.
			var wheelCenter:amPoint2d = wheel1.centerOfMass;
			var wheelRigid1:qb2IRigidObject = wheel1.getRigidsAtPoint(wheelCenter.incX(-1), 1)[0];
			var wheelRigid2:qb2IRigidObject = wheel1.getRigidsAtPoint(wheelCenter.incX(2), 1)[0];
			var bodyLeftRigid:qb2IRigidObject = carBody.getRigidsAtPoint(wheelCenter.incX(-1), 1)[0];
			var leftAxle1:qb2PistonJoint = new qb2PistonJoint(wheelRigid1, bodyLeftRigid, wheelCenter, wheelCenter);
			var leftAxle2:qb2PistonJoint = new qb2PistonJoint(wheelRigid2, bodyLeftRigid, wheelCenter, wheelCenter);
			
			//-- Do the same for the right wheel.
			wheelCenter = wheel2.centerOfMass;
			wheelRigid1 = wheel2.getRigidsAtPoint(wheelCenter.incX(-1), 1)[0];
			wheelRigid2 = wheel2.getRigidsAtPoint(wheelCenter.incX(2), 1)[0];
			var bodyRightRigid:qb2IRigidObject = carBody.getRigidsAtPoint(wheelCenter.incX(-1), 1)[0];
			var rightAxle1:qb2PistonJoint = new qb2PistonJoint(wheelRigid1, bodyRightRigid, wheelCenter, wheelCenter);
			var rightAxle2:qb2PistonJoint = new qb2PistonJoint(wheelRigid2, bodyRightRigid, wheelCenter, wheelCenter);
			
			//--- Set some properties for the shocks.
			var limit:Number = 10;
			leftAxle1.springK = leftAxle2.springK = rightAxle1.springK = rightAxle2.springK = 20;
			leftAxle1.springDamping = leftAxle2.springDamping = rightAxle1.springDamping = rightAxle2.springDamping = .75;
			leftAxle1.lowerLimit = leftAxle2.lowerLimit = rightAxle1.lowerLimit = rightAxle2.lowerLimit = -limit;
			leftAxle1.upperLimit = leftAxle2.upperLimit = rightAxle1.upperLimit = rightAxle2.upperLimit = limit;
			leftAxle1.freeRotation = leftAxle2.freeRotation = rightAxle1.freeRotation = rightAxle2.freeRotation = true;
			
			//--- Construct the car.
			car.addObject(carBody);
			car.addObject(wheel1);
			car.addObject(wheel2);
			car.addObject(leftAxle1);
			car.addObject(leftAxle2);
			car.addObject(rightAxle1);
			car.addObject(rightAxle2);
			this.addObject(car); // car is one, self-contained unit now.
			
			//--- Make a little ramp out of the inside of an elliptical arc.
			var ramp:qb2Body = qb2Stock.newEllipticalArcBody(new amPoint2d(stageWidth - rampMajor, stageHeight - rampMinor), new amVector2d( -rampMajor, 0), rampMinor, 12, AM_PI *.75, AM_PI * 1.5, rampThickness);
			ramp.position.y += rampThickness;
			ramp.friction = alteredFriction;
			this.addObject(ramp);
			
			//--- Make a keyboard, or make sure it exists.
			qb2Keyboard.makeSingleton(this.stage);
		}
		
		private function updateCar(evt:qb2UpdateEvent):void
		{
			//--- Check which keys are down and adjust torque as necessary.
			var maxTorque:Number = 100;
			var torque:Number = 0;
			if ( qb2Keyboard.singleton.isDown(Keyboard.LEFT, Keyboard.A) )
				torque -= maxTorque;
			if ( qb2Keyboard.singleton.isDown(Keyboard.RIGHT, Keyboard.D) )
				torque += maxTorque;
				
			if ( !torque )  return;
	
			//--- Search through the car's objects to find the wheels (there are obviously better ways to do this).
			for (var i:int = 0; i < car.numObjects; i++) 
			{
				//--- Apply torque to the wheels.
				var object:qb2Object = car.getObjectAt(i);
				if ( (object is qb2SoftPoly) && (object as qb2SoftPoly).isCircle )
				{
					(object as qb2SoftPoly).applyUniformTorque(torque);
				}
			}
		}
		
		//--- Jello stuff can tweak out if it doesn't have a small enough timestep.
		private var saveMaxTimeStep:Number;
		protected override function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				saveMaxTimeStep = world.maximumRealtimeStep;
				world.maximumRealtimeStep = 1.0 / 50.0;
				car.addEventListener(qb2UpdateEvent.POST_UPDATE, updateCar);
			}
			else
			{
				evt.ancestor.world.maximumRealtimeStep = saveMaxTimeStep;
				car.removeEventListener(qb2UpdateEvent.POST_UPDATE, updateCar);
			}
		}
	}
}