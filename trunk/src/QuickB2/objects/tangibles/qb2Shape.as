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
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import flash.utils.Dictionary;
	import QuickB2.*;
	import QuickB2.misc.*;
	import QuickB2.objects.joints.*;
	
	use namespace qb2_friend;
	
	use namespace am_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Shape extends qb2Tangible implements qb2IRigidObject
	{
		qb2_friend const shapeB2s:Vector.<b2Shape> = new Vector.<b2Shape>();  // must be an array, because non-convex polygons can decompose to several actual shapes...in general this will be length 1 though
		qb2_friend const fixtures:Vector.<b2Fixture> = new Vector.<b2Fixture>();
		
		qb2_friend var freezeFlush:Boolean = false;
		
		qb2_friend var flaggedForDestroy:Boolean = false;
				
		public function qb2Shape()
		{
			super();
			
			if ( (this as Object).constructor == qb2Shape )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
		}
		
		public function get b2_fixtures():Vector.<b2Fixture>
		{
			var newFixtureArray:Vector.<b2Fixture> = new Vector.<b2Fixture>();
			for (var i:int = 0; i < fixtures.length; i++) 
			{
				newFixtureArray.push(fixtures[i]);
			}
			return newFixtureArray;
		}
		
		public function get b2_body():b2Body
			{  return _bodyB2;  }
		
		public override function testPoint(point:amPoint2d):Boolean
		{
			if ( shapeB2s.length )
			{
				point = _ancestorBody ? _parent.getWorldPoint(point) : point;
				var pntB2:V2 = new V2(point.x/worldPixelsPerMeter, point.y/worldPixelsPerMeter);
				for ( var i:int = 0; i < fixtures.length; i++ )
				{
					var ithFixture:b2Fixture = fixtures[i];
					var ithShape:b2Shape = ithFixture.GetShape();
					var parentBodyB2:b2Body = ithFixture.GetBody();
					
					if ( ithShape.TestPoint( parentBodyB2.GetTransform(), pntB2) )
					{
						return true;
					}
				}
			}
			
			return false;
		}

		public override function set density(value:Number):void
		{
			updateMassProps(value * _surfaceArea - _mass, 0);
			updateFixtureDensities();
		}

		public override function set mass(value:Number):void
		{
			updateMassProps(value - _mass, 0);
			updateFixtureDensities();
		}
			
		public virtual function get perimeter():Number { return NaN; }
		public function get metricPerimeter():Number
			{ return perimeter / worldPixelsPerMeter; }
		
		protected override function setPropertyImplicitly(propName:String, value:*):void
		{
			super.setPropertyImplicitly(propName, value);
			
			rigid_setPropertyImplicitly(propName, value); // sets body properties if this shape is flying solo and has a b2Body
			
			if ( !this.fixtures.length )  return;
			
			if ( qb2Tangible.PROPS_FOR_SHAPES[propName] )
			{				
				var i:int;
				if ( propName == "restitution" )
				{
					for ( i = 0; i < this.fixtures.length; i++ )
						this.fixtures[i].SetRestitution(value as Number);
				}
				else if ( propName == "contactCategory" )
				{
					for ( i = 0; i < this.fixtures.length; i++ )
					{
						this.fixtures[i].m_filter.categoryBits = value as uint;
						this.fixtures[i].Refilter();
					}
				}
				else if ( propName == "contactCollidesWith" )
				{
					for ( i = 0; i < this.fixtures.length; i++ )
					{
						this.fixtures[i].m_filter.maskBits = value as uint;
						this.fixtures[i].Refilter();
					}
				}
				else if ( propName == "contactGroupIndex" )
				{
					for ( i = 0; i < this.fixtures.length; i++ )
					{
						this.fixtures[i].m_filter.groupIndex = value as int;
						this.fixtures[i].Refilter();
					}
				}
				else if ( propName == "friction" )
				{
					for ( i = 0; i < this.fixtures.length; i++ )
						this.fixtures[i].SetFriction(value as Number);
				}
				else if ( propName == "isGhost" )
				{
					for ( i = 0; i < this.fixtures.length; i++ )
						this.fixtures[i].SetSensor(value ? true : false);
				}
			}
		}
	
		
		public override function scaleBy(value:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			super.scaleBy(value, origin, scaleMass, scaleJointAnchors, scaleActor);
			
			if ( scaleJointAnchors )
				qb2Joint.scaleJointAnchors(value, this as qb2IRigidObject);
				
			return this;
		}
		
		
		
		private function updateFixtureDensities():void
		{
			if ( fixtures.length )
			{
				var metricDens:Number = this.metricDensity;
				for ( var i:int = 0; i < fixtures.length; i++ )
					fixtures[i].SetDensity(metricDens);
			}
		}
		
		qb2_friend function flushShapesWrapper(newMass:Number, newArea:Number):void
		{
			var oldMass:Number = _mass;
			var oldArea:Number = _surfaceArea;
			_mass = newMass;
			_surfaceArea = newArea;
			
			rigid_flushShapes();
			
			_mass = oldMass;
			_surfaceArea = oldArea;
		}
		
		qb2_friend override function rigid_flushShapes():void
		{
			if ( freezeFlush )  return;
		
			if ( _world )
			{
				pushMassFreeze(); // only makes it so b2Body::ResetMassData() is effectively not called...this has no effect on the freeze mass update flow in QuickB2
				{
					destroyShapeB2();
					makeShapeB2(_world);
				}
				popMassFreeze();
			}
		}
		
		qb2_friend override function updateFrictionJoints():void
		{
			rigid_updateFrictionJoints();
		}
		
		qb2_friend override function make(theWorld:qb2World):void
		{
			//--- If this is a lone shape being added to the world, internally it must have its own body.
			if ( !_ancestorBody )
			{
				rigid_makeBodyB2(theWorld);
			}
			
			makeShapeB2(theWorld);
			
			if ( _bodyB2 )
			{
				rigid_recomputeBodyB2Mass();
			}
			
			super.make(theWorld); // fire added to world events
		}
		
		qb2_friend function makeShapeB2(theWorld:qb2World):void
		{			
			var body:b2Body = _ancestorBody ? _ancestorBody._bodyB2 : _bodyB2;
			
			const conversion:Number = theWorld._pixelsPerMeter;
		
			//--- Populate the fixture definition.
			var fixtureDef:b2FixtureDef    = b2Def.fixture;
			fixtureDef.density             =  _mass / (_surfaceArea / (conversion * conversion));
			fixtureDef.filter.categoryBits = _contactCategory;
			fixtureDef.filter.maskBits     = _contactCollidesWith;
			fixtureDef.filter.groupIndex   = _contactGroupIndex;
			fixtureDef.friction            = _friction;
			fixtureDef.isSensor            = _isGhost;
			fixtureDef.restitution         = _restitution;
			
			var currParent:qb2Tangible = this;
			var ancestorEventFlags:uint = 0;
			while ( currParent )
			{
				ancestorEventFlags |= currParent._eventFlags;
				currParent = currParent.parent;
			}
			
			var beginContact:Boolean = ancestorEventFlags & (CONTACT_STARTED_BIT | SUB_CONTACT_STARTED_BIT) ? true : false;
			var endContact:Boolean   = ancestorEventFlags & (CONTACT_ENDED_BIT   | SUB_CONTACT_ENDED_BIT)   ? true : false;
			var preSolve:Boolean     = ancestorEventFlags & (PRE_SOLVE_BIT       | SUB_PRE_SOLVE_BIT)       ? true : false;
			var postSolve:Boolean    = ancestorEventFlags & (POST_SOLVE_BIT      | SUB_POST_SOLVE_BIT)      ? true : false;
			
			for ( var i:int = 0; i < shapeB2s.length; i++ )
			{
				fixtureDef.shape = shapeB2s[i];
				fixtures.push(body.CreateFixture(fixtureDef));
				fixtures[i].SetUserData(this);
				
				fixtures[i].m_reportBeginContact = beginContact;
				fixtures[i].m_reportEndContact   = endContact;
				fixtures[i].m_reportPreSolve     = preSolve;
				fixtures[i].m_reportPostSolve    = postSolve;
			}
		}
		
		qb2_friend override function updateContactReporting(bits:uint):void
		{
			var beginContact:Boolean = bits & (CONTACT_STARTED_BIT | SUB_CONTACT_STARTED_BIT) ? true : false;
			var endContact:Boolean   = bits & (CONTACT_ENDED_BIT   | SUB_CONTACT_ENDED_BIT)   ? true : false;
			var preSolve:Boolean     = bits & (PRE_SOLVE_BIT       | SUB_PRE_SOLVE_BIT)       ? true : false;
			var postSolve:Boolean    = bits & (POST_SOLVE_BIT      | SUB_POST_SOLVE_BIT)      ? true : false;
			
			for ( var i:int = 0; i < shapeB2s.length; i++ )
			{
				fixtures[i].m_reportBeginContact = beginContact;
				fixtures[i].m_reportEndContact   = endContact;
				fixtures[i].m_reportPreSolve     = preSolve;
				fixtures[i].m_reportPostSolve    = postSolve;
			}
		}
		
		qb2_friend override function destroy():void
		{
			if ( _bodyB2 )
			{
				rigid_destroyBodyB2();
			}
			
			destroyShapeB2();
			
			super.destroy();
		}
		
		private function destroyShapeB2():void
		{
			for ( var i:int = 0; i < fixtures.length; i++ )
			{
				var fixture:b2Fixture = fixtures[i];
				
				if ( _world.processingBox2DStuff )
				{
					_world.addDelayedCall(this, fixture.GetBody().DestroyFixture, fixture);
				}
				else
				{
					//--- qb2InternalDestructionListener marks any impliclity destroyed fixtures (fixtures that were destroyed because
					//--- the body was destroyed).  So we only have to destroy the fixture here if, e.g. this shape is being removed from a body by itself.
					if ( doNotDestroyList[fixture] )
					{
						delete doNotDestroyList[fixture];
					}
					else
					{
						fixture.GetBody().DestroyFixture(fixture);
					}
				}
				
				// fixture.SetUserData(null);
				shapeB2s[i].destroy(); // this just cleans up C++ memory...supposedly...it has nothing to do with the qb2Object::destroy() function
			}
	
			if ( this is qb2CircleShape )
			{
				_world._totalNumCircles--;
			}
			else
			{
				_world._totalNumPolygons--;
			}
			
			fixtures.length = shapeB2s.length = 0;
		}
		
		qb2_friend const doNotDestroyList:Dictionary = new Dictionary(true);
		
		
		
		
		protected override function update():void
			{  rigid_update();  }

		public override function translateBy(vector:amVector2d):qb2Tangible
			{  _position.translateBy(vector);  return this;  }

		public override function rotateBy(radians:Number, origin:amPoint2d = null):qb2Tangible 
			{  return setTransform(_position.rotateBy(radians, origin), rotation + radians) as qb2Tangible;  }

		public function setTransform(point:amPoint2d, rotationInRadians:Number):qb2IRigidObject
			{  return rigid_setTransform(point, rotationInRadians);  }

		public function updateActor():void
		{
			if ( _actor )
			{
				_actor.x = _position.x;  _actor.y = _position.y;
				_actor.rotation = rotation * TO_DEG;
			}
		}

		public function get numAttachedJoints():uint
			{  return _attachedJoints ? _attachedJoints.length : 0;  }

		public function getAttachedJointAt(index:uint):qb2Joint
			{  return _attachedJoints ? _attachedJoints[index] : null;  }
			
		public function get attachedMass():Number
			{  return rigid_attachedMass;  }

		public function get position():amPoint2d
			{  return _position;  }
		public function set position(newPoint:amPoint2d):void
			{  setTransform(newPoint, rotation);  }
			
		public function getMetricPosition():amPoint2d
		{
			const pixPer:Number = worldPixelsPerMeter;
			return new amPoint2d(_position.x / pixPer, _position.y / pixPer);
		}

		public function get linearVelocity():amVector2d
			{  return _linearVelocity;  }
		public function set linearVelocity(newVector:amVector2d):void
		{
			if ( _linearVelocity )  _linearVelocity.removeEventListener(amUpdateEvent.ENTITY_UPDATED, rigid_vectorUpdated);
			_linearVelocity = newVector;
			_linearVelocity.addEventListener(amUpdateEvent.ENTITY_UPDATED, rigid_vectorUpdated);
			rigid_vectorUpdated(null);
		}

		public function getNormal():amVector2d
			{  return amVector2d.newRotVector(0, -1, rotation);  }

		public function get rotation():Number
			{  return _rotation; }
		public function set rotation(value:Number):void
			{  setTransform(_position, value);  }

		public function get angularVelocity():Number
			{  return _angularVelocity;  }
		public function set angularVelocity(radsPerSec:Number):void
		{
			_angularVelocity = radsPerSec;
			if ( _bodyB2 )
			{
				_bodyB2.m_angularVelocity = radsPerSec;
				_bodyB2.SetAwake(true);
			}
		}
		
		public function asTangible():qb2Tangible
			{  return this as qb2Tangible;  }
	}
}