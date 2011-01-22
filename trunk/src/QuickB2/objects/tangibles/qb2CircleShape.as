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

package QuickB2.objects.tangibles
{
	import As3Math.*;
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Common.V2;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.b2FrictionJoint;
	import Box2DAS.Dynamics.Joints.b2FrictionJointDef;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.objects.joints.*;
	import QuickB2.stock.*;
	
	use namespace qb2_friend;
	use namespace am_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2CircleShape extends qb2Shape
	{
		private var _radius:Number = 0;
		
		public function qb2CircleShape() 
		{
			super();
		}
			
		qb2_friend final override function baseClone(newObject:qb2Tangible, actorToo:Boolean, deep:Boolean):qb2Tangible
		{
			if ( !newObject || newObject && !(newObject is qb2CircleShape) )
				throw new Error("newObject must be a type of qb2CircleShape.");
				
			var newCircleShape:qb2CircleShape = newObject as qb2CircleShape;
			newCircleShape.set(_position.clone(), _radius, _rotation);
			newCircleShape.copyProps(this);

			if ( actorToo && actor )
			{
				newCircleShape.actor = cloneActor();
			}
			
			return newCircleShape;
		}
		
		public function convertToPoly(numSides:uint = 12, retainJoints:Boolean = true ):qb2PolygonShape
		{
			var poly:qb2PolygonShape = qb2Stock.newRegularPolygonShape(_position.clone(), radius, numSides, _rotation);
			
			poly.copyProps(this);
			
			if ( _parent )
			{
				var index:int = _parent.getObjectIndex(this);
				_parent.setObjectAt(index, poly);
			}
				
			if ( retainJoints && _attachedJoints )
			{
				for (var i:int = 0; i < _attachedJoints.length; i++) 
				{
					var joint:qb2Joint = _attachedJoints[i--];
					
					if ( joint._object1 == this )
					{
						joint.setObject1(poly);
					}
					else if ( joint._object2 == this )
					{
						joint.setObject2(poly);
					}
					
					if ( !_attachedJoints )  break; // qb2Joint will nullify this array if the number of attached joints becomes zero, which in this case should always happen.
				}
			}
			
			return poly;
		}
		
		public function set(newPosition:amPoint2d, newRadius:Number, newRotation:Number = 0 ):qb2CircleShape
		{
			position = newPosition;
			
			_radius = newRadius;
			_rotation = newRotation;
	
			var newArea:Number = (_radius * _radius) * Math.PI;
			flushShapesWrapper(_mass, newArea);
			
			updateMassProps(0, newArea - _surfaceArea);
			
			return this;
		}
		
		public function get radius():Number
			{  return _radius;  }
		public function set radius(value:Number):void
			{  set(_position, value);  }
			
		public override function get perimeter():Number
			{  return 2 * AM_PI * _radius; }

		public override function get centerOfMass():amPoint2d
			{  return _position.clone();  }
		
		public override function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			super.scaleBy(xValue, yValue, origin, scaleMass, scaleJointAnchors);
			
			freezeFlush = true;
				_position.scaleBy(xValue, yValue, origin);
			freezeFlush = false;
			
			_radius *= (xValue + yValue)/2;
			
			var newArea:Number = (_radius * _radius) * Math.PI;
			var newMass:Number = scaleMass ? newArea * _density : _mass;
			flushShapesWrapper(newMass, newArea);
			
			updateMassProps(newMass - _mass, newArea - _surfaceArea);
			
			return this;
		}
		
		public function asCircle():amCircle2d
			{  return new amCircle2d(_position.clone(), _radius);  }
			
		qb2_friend override function makeShapeB2(theWorld:qb2World):void
		{
			if ( theWorld.processingBox2DStuff )
			{
				theWorld.addDelayedCall(this, makeShapeB2, theWorld);
				return;
			}
			
			var conversion:Number = theWorld._pixelsPerMeter;
			var circShape:b2CircleShape = new b2CircleShape();
			
			if ( !_ancestorBody )
			{
				circShape.m_p.x = circShape.m_p.y = 0;
			}
			else
			{
				var ancestorBodyLocalPosition:amPoint2d = _parent == _ancestorBody ? _position : _ancestorBody.getLocalPoint(_parent.getWorldPoint(_position));
				circShape.m_p.x = ancestorBodyLocalPosition.x / conversion;
				circShape.m_p.y = ancestorBodyLocalPosition.y / conversion;
			}
			circShape.m_radius = this._radius / conversion;
			
			shapeB2s.push(circShape);
			
			super.makeShapeB2(theWorld); // actually creates the shape from the definition(s) created here, and recomputes mass.
			
			theWorld._totalNumCircles++;
		}
		
		qb2_friend override function makeFrictionJoints():void
		{
			var numPoints:int = 4;
			var maxForce:Number = (_frictionZ * _world.gravityZ * _mass) / (numPoints as Number);
			
			populateFrictionJointArray(numPoints);
			
			var incAngle:Number = (AM_PI * 2) / (numPoints as Number);
			var reusable:amPoint2d = amPoint2d.reusable;
			var circleShape:b2CircleShape = shapeB2s[0] as b2CircleShape;
			var orig:amPoint2d = new amPoint2d(circleShape.m_p.x, circleShape.m_p.y);
			reusable.copy(orig).incY( -circleShape.m_radius);
			
			for (var i:int = 0; i < frictionJoints.length; i++) 
			{
				var ithFrictionJoint:b2FrictionJoint = frictionJoints[i];
				
				ithFrictionJoint.m_maxForce  = maxForce;
				ithFrictionJoint.m_maxTorque = 0;// maxForce;
				
				ithFrictionJoint.m_localAnchorA.x = reusable.x;
				ithFrictionJoint.m_localAnchorA.y = reusable.y;
				
				reusable.rotateBy(incAngle, orig);
			}
		}
		
		public override function testPoint(point:amPoint2d):Boolean
		{
			if ( shapeB2s.length )
			{
				return super.testPoint(point);
			}
			else
			{
				return point.distanceTo(_position) <= radius;
			}
		}
		
		public override function draw(graphics:Graphics):void
		{			
			var vertex:amPoint2d = (_parent is qb2Body ) ? (_parent as qb2Body ).getWorldPoint(_position) : _position
			graphics.drawCircle(vertex.x, vertex.y, _radius);
		}
		
		public override function drawDebug(graphics:Graphics):void
		{
			var staticShape:Boolean = mass == 0;
			
			var drawFlags:uint = qb2DebugDrawSettings.drawFlags;
			
			if ( drawFlags & qb2DebugDrawSettings.DRAW_OUTLINES )
				graphics.lineStyle(qb2DebugDrawSettings.lineThickness, debugOutlineColor, qb2DebugDrawSettings.outlineAlpha);
			else
				graphics.lineStyle();
			if ( drawFlags & qb2DebugDrawSettings.DRAW_FILLS )
				graphics.beginFill(debugFillColor, qb2DebugDrawSettings.fillAlpha);
				
			draw(graphics);
			
			graphics.endFill();
			
			if ( (drawFlags & qb2DebugDrawSettings.DRAW_OUTLINES) && (drawFlags & qb2DebugDrawSettings.DRAW_CIRCLE_SPOKES) )
			{
				//graphics.lineStyle(qb2DebugDrawSettings.lineThickness, staticShape ? qb2DebugDrawSettings.staticOutlineColor : qb2DebugDrawSettings.dynamicOutlineColor, qb2DebugDrawSettings.outlineAlpha);
				var vertex:amPoint2d = _parent ? _parent.getWorldPoint(_position) : _position;
				var upVec:amVector2d = amVector2d.newRotVector(0, -1, _rotation).scaleBy(_radius);
				var vec:amVector2d = _parent ? _parent.getWorldVector(upVec) : upVec;
				var inc:Number = 0;
				
				var spokeFlags:Array =
				[
					qb2DebugDrawSettings.DRAW_CIRCLE_SPOKE_1, qb2DebugDrawSettings.DRAW_CIRCLE_SPOKE_2,
					qb2DebugDrawSettings.DRAW_CIRCLE_SPOKE_3, qb2DebugDrawSettings.DRAW_CIRCLE_SPOKE_4
				];
				
				for (var i:int = 0; i < spokeFlags.length; i++) 
				{
					if ( drawFlags & spokeFlags[i] )
					{
						if ( inc )
						{
							vec.rotateBy(inc);
							inc = 0;
						}
						
						graphics.moveTo(vertex.x, vertex.y);
						var moved:amPoint2d = vertex.translatedBy(vec);
						graphics.lineTo(moved.x, moved.y);
					}
					
					inc += RAD_90;
				}
			}
			
			super.drawDebug(graphics);
		}
		
		public override function toString():String 
			{  return qb2DebugTraceSettings.formatToString(this, "qb2CircleShape");  }
	}
}