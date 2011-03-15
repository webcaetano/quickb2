package demos 
{
	import As3Math.consts.RAD_10;
	import As3Math.geo2d.amPoint2d;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.events.qb2UpdateEvent;
	import QuickB2.misc.qb2Mouse;
	import QuickB2.objects.joints.qb2DistanceJoint;
	import QuickB2.objects.joints.qb2MouseJoint;
	import QuickB2.objects.joints.qb2PistonJoint;
	import QuickB2.objects.joints.qb2RevoluteJoint;
	import QuickB2.objects.joints.qb2WeldJoint;
	import QuickB2.objects.tangibles.qb2CircleShape;
	import QuickB2.objects.tangibles.qb2PolygonShape;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * All the joints that QuickB2 exposes.
	 * 
	 * @author Doug Koellmer
	 */
	public class Joints extends Demo
	{
		private var mouseJointTarget:amPoint2d;
		private var mouseJointCenter:amPoint2d;
		private static const mouseJointTargetRadius:Number = 100;
		
		public function Joints() 
		{
			var incX:Number = stageWidth / 5;
			var incY:Number = stageHeight / 3;
			var currX:Number = incX;
			var currY:Number = incY;
			var jointLengths:Number = 100;
			var rectWidth:Number = 60, rectHeight:Number = 40;
			var circRadius:Number = 30;
			var rect1:qb2PolygonShape, rect2:qb2PolygonShape;
			var circ:qb2CircleShape;
			
			//--- Make a spring that attaches two rectangles and syncs their rotations.
			rect1 = qb2Stock.newRectShape(new amPoint2d(currX, currY + jointLengths / 2), rectWidth, rectHeight, 1);
			rect2 = rect1.clone() as qb2PolygonShape;
			rect2.position.y -= jointLengths;
			var pistonJoint:qb2PistonJoint = new qb2PistonJoint(rect1, rect2);
			pistonJoint.springK = 30;
			pistonJoint.springDamping = .75;
			pistonJoint.springCanFlip = true;
			addObject(rect1, rect2, pistonJoint);
			
			//--- Make an identical spring, but one that lets the second object spin freely
			//--- This is like b2LineJoint in Box2D, but wrapped into one joint with a simple flag.
			currX += incX;
			rect1 = rect1.clone() as qb2PolygonShape;
			rect2 = rect2.clone() as qb2PolygonShape;
			rect1.position.x = currX;
			rect2.position.x = currX;
			pistonJoint = pistonJoint.clone() as qb2PistonJoint;
			pistonJoint.object1 = rect1;
			pistonJoint.object2 = rect2;
			pistonJoint.freeRotation = true;  // b2LineJoint with one line of code!
			addObject(rect1, rect2, pistonJoint);
			
			//--- A distance joint keeps two objects a certain distance apart.
			currX += incX;
			rect1 = rect1.clone() as qb2PolygonShape;
			rect2 = rect2.clone() as qb2PolygonShape;
			rect1.position.x = currX;
			rect2.position.x = currX;
			var distanceJoint:qb2DistanceJoint = new qb2DistanceJoint(rect1, rect2);
			addObject(rect1, rect2, distanceJoint);
			
			//--- A distance joint can also be configured to not have a minimum constraint.
			//--- This is like b2RopeJoint in Box2D, which is here toggled with a flag.
			currX += incX;
			rect1 = rect1.clone() as qb2PolygonShape;
			rect2 = rect2.clone() as qb2PolygonShape;
			rect1.position.x = currX;
			rect2.position.x = currX;
			distanceJoint = distanceJoint.clone() as qb2DistanceJoint;
			distanceJoint.object1 = rect1;
			distanceJoint.object2 = rect2;
			distanceJoint.isRope = true;  // like b2RopeJoint.
			addObject(rect1, rect2, distanceJoint);
			
			incX = stageWidth / 4;
			currX = incX;
			currY += incY;
			
			//--- A revolute joint can be used for things like axels, motors, and angular springs.
			rect1 = rect1.clone() as qb2PolygonShape;
			rect2 = rect2.clone() as qb2PolygonShape;
			rect1.position.set(currX, currY);
			rect2.position.set(currX, currY-jointLengths/2);
			var revJoint:qb2RevoluteJoint = new qb2RevoluteJoint(rect1, rect2);
			revJoint.springK = pistonJoint.springK * 2;
			revJoint.springDamping = pistonJoint.springDamping;
			addObject(rect1, rect2, revJoint);
			
			//--- Weld joint is pretty basic, just fixes two objects together as tight as possible.
			currX += incX;
			rect1 = rect1.clone() as qb2PolygonShape;
			rect2 = rect2.clone() as qb2PolygonShape;
			rect1.position.set(currX-rectWidth/2, currY-rectHeight/2);
			rect2.position.set(currX+rectWidth/2, currY+rectHeight/2);
			var weldJoint:qb2WeldJoint = new qb2WeldJoint(rect1, rect2, new amPoint2d(currX, currY));
			addObject(rect1, rect2, weldJoint);
			
			//--- A mouse joint is usually driven by a mouse, but you can programmatically control it as well.
			currX += incX;
			mouseJointCenter = new amPoint2d(currX, currY);
			mouseJointTarget = new amPoint2d(currX, currY - jointLengths);
			rect1 = rect1.clone() as qb2PolygonShape;
			rect1.position.set(currX, currY);
			var mouseJoint:qb2MouseJoint = new qb2MouseJoint(rect1, new amPoint2d(currX + rectWidth / 2, currY));
			mouseJoint.worldTarget = mouseJointTarget;
			mouseJoint.maxForce = rect1.mass * 100;
			addObject(rect1, mouseJoint);
			
			//--- Tilt everything by a little bit, just so things fall a little more interestingly.
			this.rotateBy(RAD_10, new amPoint2d(stageWidth / 2, stageHeight / 2));
			
			this.addEventListener(qb2UpdateEvent.POST_UPDATE, updateMouseTarget);
		}
		
		//--- Control the mouse joint with code.
		private function updateMouseTarget(evt:qb2UpdateEvent):void
		{
			mouseJointTarget.rotateBy(RAD_10, mouseJointCenter);
		}
		
		protected override function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
				this.addEventListener(qb2UpdateEvent.POST_UPDATE, updateMouseTarget);
			else
				this.removeEventListener(qb2UpdateEvent.POST_UPDATE, updateMouseTarget);
		}
	}
}