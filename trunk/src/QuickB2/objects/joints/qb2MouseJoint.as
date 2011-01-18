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
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	use namespace am_friend;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2MouseJoint extends qb2Joint
	{
		private var _worldTarget:amPoint2d = null;
		
		private var _maxForce:Number = 100;
		private var _frequencyHz:Number = 5.0;
		private var _dampingRatio:Number = .7;
	
		public function qb2MouseJoint(initObject:qb2IRigidObject = null, initWorldAnchor:amPoint2d = null) 
		{
			requiresTwoRigids = false;
			hasOneWorldPoint = true;
			
			object = initObject;
			
			_maxForce = 100;
			
			worldTarget = new amPoint2d();
			
			setWorldAnchor(initWorldAnchor ? initWorldAnchor : initWorldPoint(initObject));
		}
		
		public function get localAnchor():amPoint2d
			{  return _localAnchor2;  }
		public function set localAnchor(newPoint:amPoint2d):void
			{  setLocalAnchor2(newPoint);  }
		
		public function get worldTarget():amPoint2d
			{  return _worldTarget;  }
		public function set worldTarget(newPoint:amPoint2d):void
		{
			if ( _worldTarget )  _worldTarget.removeEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired);
			_worldTarget = newPoint;
			_worldTarget.addEventListener(amUpdateEvent.ENTITY_UPDATED, entityEventFired);
			anchorUpdated(_worldTarget);
		}
		
		public function getWorldAnchor():amPoint2d
		{
			return _object2 ? (_object2 as qb2Tangible).getWorldPoint(_localAnchor2) : _localAnchor2.clone();
		}
		
		public function setWorldAnchor(worldAnchor:amPoint2d):void
		{
			localAnchor = _object2 ? _object2.getLocalPoint(worldAnchor) : worldAnchor.clone();
		}
		
		qb2_friend override function anchorUpdated(point:amPoint2d):void
		{
			if ( jointB2 )
			{
				if ( point == _localAnchor2 )
				{
					correctLocals();
				}
				else
				{
					var conversion:Number = worldPixelsPerMeter;
					var pntB2:V2 = new V2(_worldTarget.x / conversion, _worldTarget.y / conversion);
					joint.SetTarget(pntB2);
				}
				
				wakeUpAttached();
			}
		}
		
		qb2_friend override function correctLocals():void
		{
			if ( jointB2 )
			{
				var corrected:amPoint2d = getCorrectedLocal2(worldPixelsPerMeter, worldPixelsPerMeter);
				
				joint.m_localAnchor.x = corrected.x;
				joint.m_localAnchor.y = corrected.y;
			}
		}
		
		public function get frequencyHz():Number
			{  return _frequencyHz;  }
		public function set frequencyHz(value:Number):void
		{
			_frequencyHz = value;
			if ( jointB2 )
				joint.SetFrequency(value);
		}
		
		public function get dampingRatio():Number
			{  return _dampingRatio;  }
		public function set dampingRatio(value:Number):void
		{
			_dampingRatio = value;
			if ( jointB2 )
				joint.SetDampingRatio(value);
		}
		
		public function get maxForce():Number
			{  return _maxForce;  }
		public function set maxForce(value:Number):void
		{
			_maxForce = value;
			if ( jointB2 )
				joint.SetMaxForce(value);
		}
		
		public function get object():qb2IRigidObject
			{  return _object2 as qb2IRigidObject;   }
		public function set object(newObject:qb2IRigidObject):void
			{  setObject2(newObject);  }
		
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
				
				var mouseJointDef:b2MouseJointDef = b2Def.mouseJoint;
				var worldTargetPnt:amPoint2d = _object2.getWorldPoint(_localAnchor2);
				mouseJointDef.target.x = worldTargetPnt.x / conversion;
				mouseJointDef.target.y = worldTargetPnt.y / conversion;
				mouseJointDef.frequencyHz = _frequencyHz;
				mouseJointDef.dampingRatio = _dampingRatio;
				mouseJointDef.maxForce = _maxForce;
				
				
				jointDef = mouseJointDef;
				_object1 = theWorld.background;  // Box2d requires another b2Body for this joint for some insane reason, so temporarily set this just to the background
			}
			
			super.makeJointB2(theWorld);
			
			if ( joint && theWorld )
			{
				joint.m_target.x = _worldTarget.x / theWorld.pixelsPerMeter;
				joint.m_target.y = _worldTarget.y / theWorld.pixelsPerMeter;
			}
			
			
			_object1 = null;
		}
		
		private function get joint():b2MouseJoint
			{  return jointB2 ? jointB2 as b2MouseJoint : null;  }
			
		public override function clone():qb2Object
		{
			var mouseJoint:qb2MouseJoint = new qb2MouseJoint();
			
			mouseJoint._localAnchor2._x = this._localAnchor2._x;
			mouseJoint._localAnchor2._y = this._localAnchor2._y;
			
			mouseJoint.collideConnected = this.collideConnected;
			mouseJoint.frequencyHz = this.frequencyHz;
			mouseJoint.dampingRatio = this.dampingRatio;
			mouseJoint.maxForce = this.maxForce;
			
			return mouseJoint;
		}
		
		public static var arrowDrawSize:Number = 8;
		
		public override function draw(graphics:Graphics):void
		{
			var worldPoints:Vector.<V2> = drawAnchors(graphics);
			
			graphics.endFill();
			
			if ( !worldPoints )   return;
			
			var world1:amPoint2d = reusableDrawPoint.set(worldPoints[0].x, worldPoints[0].y);
			
			var diff:amVector2d = worldTarget.minus(world1);
			
			if ( diff.lengthSquared > 1 ) // Not checking for this would causes some sloppy graphics.
				diff.draw(graphics, world1, 0, arrowDrawSize);
		}
		
		qb2_friend override function getWorldAnchors():Vector.<V2>
		{
			reusableV2.xy(joint.m_localAnchor.x, joint.m_localAnchor.y);
			var anch1:V2 = joint.m_bodyB.GetWorldPoint(reusableV2);
			anch1.multiplyN(worldPixelsPerMeter);
			
			return Vector.<V2>([anch1]);
		}
		
		public override function toString():String 
			{  return qb2DebugTraceSettings.formatToString(this, "qb2MouseJoint");  }
	}
}