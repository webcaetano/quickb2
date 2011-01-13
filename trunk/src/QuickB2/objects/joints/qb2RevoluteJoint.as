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

package QuickB2.objects.joints
{
	import As3Math.*;
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	use namespace am_friend;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2RevoluteJoint extends qb2Joint
	{		
		public var springK:Number = 0;
		public var springDamping:Number = 0;
		public var springCanFlip:Boolean = false;
		public var dampenSpringJitter:Boolean = false;
		public var optimizedSpring:Boolean = true;
		
		private var _lowerAngle:Number = -Infinity;
		private var _upperAngle:Number = Infinity;
		private var _maxMotorTorque:Number = 0;
		private var _targetMotorSpeed:Number = 0;
		private var _referenceAngle:Number = 0;
		
		public function qb2RevoluteJoint(initObject1:qb2IRigidObject = null, initObject2:qb2IRigidObject = null, initWorldAnchor:amPoint2d = null) 
		{
			hasOneWorldPoint = true;
		
			object1 = initObject1;
			object2 = initObject2;
			
			setWorldAnchor(initWorldAnchor ? initWorldAnchor : initWorldPoint(object1));
		}
		
		public function get localAnchor1():amPoint2d
			{  return _localAnchor1;  }
		public function set localAnchor1(newPoint:amPoint2d):void
			{  setLocalAnchor1(newPoint);  }
		
		public function get localAnchor2():amPoint2d
			{  return _localAnchor2;  }
		public function set localAnchor2(newPoint:amPoint2d):void
			{  setLocalAnchor2(newPoint);  }
		
		public function getWorldAnchor():amPoint2d
		{
			var world1:amPoint2d = _object1 ? (_object1 as qb2Tangible).getWorldPoint(_localAnchor1) : _localAnchor1.clone();
			var world2:amPoint2d = _object2 ? (_object2 as qb2Tangible).getWorldPoint(_localAnchor2) : _localAnchor2.clone();
			return world1.midwayPoint(world2);
		}
		
		public function setWorldAnchor(worldAnchor:amPoint2d):void
		{
			localAnchor1 = _object1 ? (_object1 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
			localAnchor2 = _object2 ? (_object2 as qb2Tangible).getLocalPoint(worldAnchor) : worldAnchor.clone();
		}
		
		qb2_friend override function anchorUpdated(point:amPoint2d):void
		{
			correctLocals();
			wakeUpAttached();
		}
		
		qb2_friend override function correctLocals():void
		{
			if ( jointB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var corrected1:amPoint2d = getCorrectedLocal1(conversion);
				var corrected2:amPoint2d = getCorrectedLocal2(conversion);
				
				joint.m_localAnchor1.x = corrected1.x;
				joint.m_localAnchor1.y = corrected1.y;
				joint.m_localAnchor2.x = corrected2.x;
				joint.m_localAnchor2.y = corrected2.y;
			}
		}
		
		
		public function get lowerAngle():Number
			{  return _lowerAngle;  }
		public function set lowerAngle(value:Number):void
		{
			_lowerAngle = value;
			
			updateLimits();
			wakeUpAttached();
		}
		
		public function get upperAngle():Number
			{  return _upperAngle;  }
		public function set upperAngle(value:Number):void
		{
			_upperAngle = value;
			
			updateLimits();
			wakeUpAttached();
		}
		
		public function setLimits(lower:Number, upper:Number):void
		{
			lowerAngle = lower;
			upperAngle = upper;
		}
		
		private function updateLimits():void
		{
			if ( !jointB2 )  return;
			
			var conversion:Number = world.pixelsPerMeter;
			
			joint.SetLimits(_lowerAngle / conversion, _upperAngle / conversion);
			joint.EnableLimit(hasLimits);
		}
		
		public function get hasLimits():Boolean
			{  return isFinite(_lowerAngle) || isFinite(_upperAngle);  }
		
		public function get referenceAngle():Number
			{  return _referenceAngle;  }
		public function set referenceAngle(value:Number):void
		{
			_referenceAngle = value;
			if( jointB2 )  joint.m_referenceAngle = _referenceAngle;
			wakeUpAttached();
		}
		
		public function get currJointAngle():Number
			{  return jointB2 ? joint.GetJointAngle() : 0;  }
			
		public function get currMotorSpeed():Number
			{  return jointB2 ? joint.GetJointSpeed() : 0;  }
			
		public function get currTorque():Number
			{  return jointB2 ? joint.GetMotorTorque() : 0;  }
			
		public function get targetMotorSpeed():Number
			{  return _targetMotorSpeed;  }
		public function set targetMotorSpeed(value:Number):void
		{
			if ( !callingFromUpdate && optimizedSpring && springK )
				throw qb2_errors.OPT_SPRING_ERROR;
				
			_targetMotorSpeed = value;
			if ( jointB2 )
				joint.SetMotorSpeed(value);
		}
		
		public function get maxMotorTorque():Number
			{  return _maxMotorTorque;  }
		public function set maxMotorTorque(value:Number):void
		{
			if ( !callingFromUpdate && optimizedSpring && springK )
				throw qb2_errors.OPT_SPRING_ERROR;
			
			_maxMotorTorque = value;
			if ( jointB2 )
			{
				joint.SetMaxMotorTorque(value);
				joint.EnableMotor(value ? true : false);
			}
		}
		
		public function get object1():qb2IRigidObject
			{  return _object1 as qb2IRigidObject;   }
		public function set object1(newObject:qb2IRigidObject):void
			{  setObject1(newObject);  }
		
		public function get object2():qb2IRigidObject
			{  return _object2 as qb2IRigidObject;  }
		public function set object2(newObject:qb2IRigidObject):void
			{  setObject2(newObject);  }
		
		qb2_friend override function objectsUpdated():void
		{
			if ( _object1 && _object2 )
				referenceAngle = _object2._rotation - _object1._rotation;
		}
		
		qb2_friend override function makeJointB2(theWorld:qb2World):void
		{
			if ( theWorld && theWorld.processingBox2DStuff )
			{
				theWorld.addDelayedCall(this, makeJointB2, theWorld);
				return;
			}
			
			if ( checkForMake(theWorld) )
			{
				var conversion:Number = theWorld.pixelsPerMeter;
				var corrected1:amPoint2d    = getCorrectedLocal1(conversion);
				var corrected2:amPoint2d    = getCorrectedLocal2(conversion);
				
				var revJointDef:b2RevoluteJointDef = b2Def.revoluteJoint;
				revJointDef.localAnchorA.x   = corrected1.x;
				revJointDef.localAnchorA.y   = corrected1.y;
				revJointDef.localAnchorB.x   = corrected2.x;
				revJointDef.localAnchorB.y   = corrected2.y;
				
				revJointDef.enableLimit = hasLimits;
				revJointDef.enableMotor = _maxMotorTorque ? true : false;
				revJointDef.lowerAngle = _lowerAngle;
				revJointDef.upperAngle = _upperAngle;
				revJointDef.maxMotorTorque = _maxMotorTorque;
				revJointDef.motorSpeed = _targetMotorSpeed;
				revJointDef.referenceAngle = _referenceAngle;
				
				jointDef = revJointDef;
			}
			
			super.makeJointB2(theWorld);
		}
		
		private function get joint():b2RevoluteJoint
			{  return jointB2 ? jointB2 as b2RevoluteJoint : null;  }
			
		private var callingFromUpdate:Boolean = false;
		
		protected override function update():void
		{
			if ( springK == 0 )  return;
			if ( !_object1 || !_object2 || !_object2.world || !_object2.world )  return;
			if ( _object1.isSleeping && _object2.isSleeping )  return;
			
			var jointAngle:Number = this.currJointAngle;
			if ( springCanFlip )
			{
				 //--- Basically do a kind of modulus on the angle here to allow it to flip...
				var sign:Number = amUtils.sign(jointAngle);
				var modAngle:Number = Math.abs(jointAngle) % (AM_PI * 2);
				jointAngle = modAngle > AM_PI ? sign * (modAngle - AM_PI * 2) : sign*modAngle;
			}
			
			if ( optimizedSpring )
			{
				callingFromUpdate = true;
				{
					maxMotorTorque = Math.abs((jointAngle * springK) + (currMotorSpeed * springDamping));
					targetMotorSpeed = jointAngle > 0 ? -MAX_SPRING_SPEED : MAX_SPRING_SPEED;
				}
				callingFromUpdate = false;
			}
			
			/*var conversion:Number = worldPixelsPerMeter;
		
			var world1:amPoint2d = getWorldAnchor1();
			var world2:amPoint2d = getWorldAnchor2();
			
			var diff:amVector2d = world2.minus(world1);
			var diffLen:Number = diff.length;
			diff.normalize();
			
			//--- Make it so the spring doesn't "flip" around if so chosen, because by default the distance between objects isn't signed.
			var worldAxis:amVector2d
			if ( !springCanFlip )
			{
				worldAxis = _object1.getWorldVector(_localDirection);
				if ( worldAxis.dotProduct(diff) < 0 )
				{
					diffLen = -diffLen;
					diff.negate();
				}
			}
			
			diff.scaleBy( ((diffLen - springLength)/conversion) * springK );
			
			_object1.applyForce(world1, diff);
			_object2.applyForce(world2, diff.negate());
			
			if ( springDamping )
			{
				var linVel1:amVector2d = _object1.getLinearVelocityAtPoint(world1);
				var linVel2:amVector2d = _object2.getLinearVelocityAtPoint(world2);
				
				var velDiff:amVector2d = linVel2.minus(linVel1).normalize();
				var dampingForceVec:amVector2d = diff.normalize();
				dampingForceVec.scaleBy(velDiff.dotProduct(dampingForceVec) * springDamping);
				_object1.applyForce(world1, dampingForceVec);
				_object2.applyForce(world2, dampingForceVec.negate());
			}*/
		}
			
		public override function clone():qb2Object
		{
			var revJoint:qb2RevoluteJoint = new qb2RevoluteJoint();
			
			revJoint._localAnchor1._x = this._localAnchor1._x;
			revJoint._localAnchor1._y = this._localAnchor1._y;
			
			revJoint._localAnchor2._x = this._localAnchor2._x;
			revJoint._localAnchor2._y = this._localAnchor2._y;
			
			revJoint._collideConnected   = this._collideConnected;
			revJoint._lowerAngle         = this._lowerAngle;
			revJoint._maxMotorTorque     = this._maxMotorTorque;
			revJoint._targetMotorSpeed   = this._targetMotorSpeed;
			revJoint._upperAngle         = this._upperAngle;
			revJoint._referenceAngle     = this._referenceAngle;
			
			revJoint.springK             = this.springK;
			revJoint.springDamping       = this.springDamping;
			revJoint.springCanFlip       = this.springCanFlip;
			revJoint.dampenSpringJitter  = this.dampenSpringJitter;
			revJoint.optimizedSpring     = this.optimizedSpring;
			
			return revJoint;
		}
		
		public static var arrowDrawRadius:Number = anchorDrawRadius*3;
		
		public override function draw(graphics:Graphics):void
		{
			var worldPoints:Vector.<amPoint2d> = drawAnchors(graphics);
			
			graphics.endFill();
			
			if (!worldPoints )   return;
			 
			var world1:amPoint2d = worldPoints[0];
			
			var arrowSize:Number = arrowDrawRadius * .25;
			
			graphics.moveTo(world1.x, world1.y-arrowDrawRadius);
			graphics.curveTo(world1.x + arrowDrawRadius, world1.y - arrowDrawRadius, world1.x + arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x + arrowDrawRadius - arrowSize, world1.y - arrowSize);
			graphics.moveTo(world1.x + arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x + arrowDrawRadius + arrowSize, world1.y - arrowSize);
			
			graphics.moveTo(world1.x, world1.y+arrowDrawRadius);
			graphics.curveTo(world1.x - arrowDrawRadius, world1.y + arrowDrawRadius, world1.x - arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x - arrowDrawRadius - arrowSize, world1.y + arrowSize);
			graphics.moveTo(world1.x - arrowDrawRadius, world1.y);
			graphics.lineTo(world1.x - arrowDrawRadius + arrowSize, world1.y + arrowSize);
		}
		
		public override function toString():String 
			{  return qb2DebugTraceSettings.formatToString(this, "qb2RevoluteJoint");  }
	}
}