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
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.*;
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.effects.*;
	import QuickB2.events.*;
	import QuickB2.loaders.proxies.*;
	import QuickB2.misc.qb2_flags;
	import QuickB2.misc.qb2_props;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.stock.*;
	import As3Math.am_friend;
	
	use namespace qb2_friend;
	
	use namespace am_friend;
	
	[Event(name="preSolve",       type="QuickB2.events.qb2ContactEvent")]
	[Event(name="postSolve",      type="QuickB2.events.qb2ContactEvent")]
	[Event(name="contactStarted", type="QuickB2.events.qb2ContactEvent")]
	[Event(name="contactEnded",   type="QuickB2.events.qb2ContactEvent")]
	
	[Event(name="massPropsChanged",   type="QuickB2.events.qb2MassEvent")]

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Tangible extends qb2Object
	{
		qb2_friend static const diffTol:Number = .0000000001;
		qb2_friend static const rotTol:Number = .0000001;
		
		public function get ancestorBody():qb2Body
			{  return _ancestorBody;  }
		qb2_friend function setAncestorBody(aBody:qb2Body):void
			{  _ancestorBody = aBody;  }
		qb2_friend var _ancestorBody:qb2Body;
		
		//--- These are used for qb2IRigidObject's "implementation".  Since qb2IRigidObject is only an interface, it can't store variables.
		//--- It's a bit of a waste of space to have these member references here when this object isn't necessarily a qb2IRigidObject (i.e. when it's a qb2Group
		//--- or qb2World), but most objects in a simulation will be qb2IRigidObjects anyway, and the only other alternatives are (A) store them in
		//--- a "mixin" file like qb2InternalRigidBody_impl.as, which makes more sense conceptually and memory-wise, but would mean that here in qb2Tangible
		//--- you'd have to get access to these variables by reflection in some cases, e.g. this["_linearVelocity"], which sucks, AND messes up code completion,
		//--- or (B) to have completely identical code in qb2IRigidObject's two implementers, qb2Body and qb2Shape, which is bad for what should be obvious reasons.
		qb2_friend var _bodyB2:b2Body;
		qb2_friend var _attachedJoints:Vector.<qb2Joint> = null;
		qb2_friend var _linearVelocity:amVector2d = null;
		qb2_friend var _angularVelocity:Number = 0;
		qb2_friend var _position:amPoint2d = null;
		qb2_friend var _rotation:Number = 0;
		qb2_friend var _calledFromPointUpdated:Boolean = false;
		
		public function qb2Tangible():void
		{
			if ( this is qb2IRigidObject )
			{
				var rigid:qb2IRigidObject = this as qb2IRigidObject;
				_position = new amPoint2d();
				_position.addEventListener(amUpdateEvent.ENTITY_UPDATED, rigid_pointUpdated);
				_linearVelocity = new amVector2d();
				_linearVelocity.addEventListener(amUpdateEvent.ENTITY_UPDATED, rigid_vectorUpdated);
			}
			
			if ( (this as Object).constructor == qb2Tangible )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
			
			//--- Set up default values for various properties.
			turnFlagOn(qb2_flags.T_IS_DEBUG_DRAGGABLE,             true);
			setProperty(qb2_props.T_CONTACT_CATEGORY,      0x0001, true);
			setProperty(qb2_props.T_CONTACT_COLLIDES_WITH, 0xFFFF, true);
			setProperty(qb2_props.T_FRICTION,              .2,     true);
		}
		
		qb2_friend virtual function baseClone(newObject:qb2Tangible, actorToo:Boolean, deep:Boolean):qb2Tangible {  return null;  }
		
		qb2_friend virtual function updateContactReporting(bits:uint):void { }
		
		qb2_friend function rigid_flagsChanged(affectedFlags:uint):void
		{
			//--- Make actual changes to a simulating body if the property has an actual effect.
			if ( this._bodyB2 )
			{
				if ( affectedFlags & qb2_flags.T_IS_KINEMATIC )
				{
					rigid_recomputeBodyB2Mass();
					updateFrictionJoints();
				}
				
				if ( affectedFlags & qb2_flags.T_HAS_FIXED_ROTATION )
				{
					this._bodyB2.SetFixedRotation(hasFixedRotation );
					this._bodyB2.SetAwake(true);
					(this as qb2IRigidObject).angularVelocity = 0; // object won't stop spinning if we don't stop it manually, because now it has infinite intertia.
				}
				
				if ( affectedFlags & qb2_flags.T_IS_BULLET )
				{
					this._bodyB2.SetBullet(isBullet);
				}
				
				if ( affectedFlags & qb2_flags.T_ALLOW_SLEEPING )
				{
					this._bodyB2.SetSleepingAllowed(allowSleeping);
				}
			}
		}
		
		qb2_friend final function rigid_propertyChanged(propertyName:String):void
		{
			//--- Make actual changes to a simulating body if the property has an actual effect.
			if ( this._bodyB2 )
			{
				if ( propertyName == qb2_props.T_LINEAR_DAMPING )
				{
					this._bodyB2.m_linearDamping = linearDamping;
				}
				else if ( propertyName == qb2_props.T_ANGULAR_DAMPING )
				{
					this._bodyB2.m_angularDamping = angularDamping;
				}
			}
		}
		
		qb2_friend function cloneActor():DisplayObject
		{
			var actorClone:DisplayObject = new (Object(this._actor).constructor as Class) as DisplayObject;
			actorClone.transform.matrix = actor.transform.matrix.clone();
			
			//--- An actor can only contain proxies that should be deleted if
			//--- it itself is a proxy, so this check can save some search time.
			if ( actorClone is qb2Proxy )
			{
				var container:DisplayObjectContainer = actorClone as DisplayObjectContainer;
				var numChildren:int = container.numChildren;
				for (var i:int = 0; i < container.numChildren; i++) 
				{
					if ( container.getChildAt(i) is qb2Proxy )
					{
						container.removeChildAt(i--);
					}
				}
			}
			
			return actorClone;
		}
		
		qb2_friend function removeActor():void
		{
			if ( _actor && _actor.parent && _parent && _parent._actor == _actor.parent )
			{
				_actor.parent.removeChild(_actor);
			}
		}
		
		qb2_friend function addActor():void
		{
			if ( _actor && !_actor.parent && _parent )
			{
				if( _parent._actor && (_parent._actor is DisplayObjectContainer) )
					(_parent._actor as DisplayObjectContainer).addChild(_actor);
			}
		}
		
		private var massFreezeStack:Vector.<Boolean>;
		
		qb2_friend function pushMassFreeze():void
		{
			if ( _bodyB2 )
			{
				_bodyB2.SetType(b2Body.b2_staticBody);
			}
			else if( _ancestorBody && _ancestorBody._bodyB2 )
			{
				_ancestorBody._bodyB2.SetType(b2Body.b2_staticBody);
			}
			
			if ( !massFreezeStack )
				massFreezeStack = new Vector.<Boolean>();
			massFreezeStack.push(true);
		}
		
		qb2_friend function popMassFreeze():void
		{
			if ( massFreezeStack )
			{
				massFreezeStack.pop();
				if ( massFreezeStack.length == 0 )
					massFreezeStack = null;
			}
		}
		
		private function get massUpdateFrozen():Boolean
			{  return massFreezeStack ? true : false;  }
			
		qb2_friend function updateMassProps(massDiff:Number, areaDiff:Number, skipFirst:Boolean = false ):void
		{
			var original:qb2Tangible = this;
			var currParent:qb2Tangible = this;
			while (currParent)
			{
				if ( currParent.massUpdateFrozen )  return;
				
				var beforeMass:Number = currParent._mass;
				var beforeArea:Number = currParent._surfaceArea;
				var beforeDens:Number = currParent._density;
				
				if ( areaDiff || massDiff )
				{
					currParent._surfaceArea += areaDiff;
					currParent._mass        += massDiff;
					currParent._density = currParent._mass / currParent._surfaceArea;
				}
				
				if ( currParent._bodyB2 )
				{
					currParent.rigid_recomputeBodyB2Mass();
					currParent._bodyB2.SetAwake(true);
				}
				else if ( currParent._ancestorBody && currParent._ancestorBody._bodyB2 )
				{
					currParent._ancestorBody._bodyB2.SetAwake(true);
				}
				
				if ( currParent.eventFlags & MASS_CHANGED_BIT )
				{
					if ( skipFirst && currParent != original || !skipFirst )
					{
						var evt:qb2MassEvent = getCachedEvent("massPropsChanged");
						evt._affectedObject  = currParent;
						evt._massChange      = currParent._mass        - beforeMass;
						evt._areaChange      = currParent._surfaceArea - beforeArea;
						evt._densityChange   = currParent._density     - beforeDens;
						currParent.dispatchEvent(evt);
					}
				}
				
				if ( currParent is qb2Shape )
				{
					currParent.updateFrictionJoints();
				}
				
				currParent = currParent._parent;
			}
		}
	
		
		public function get effects():Vector.<qb2Effect>
			{ return _effects; }
		public function set effects(value:Vector.<qb2Effect>):void 
			{  _effects = value;  }
		private var _effects:Vector.<qb2Effect>;
		
		public function get actor():DisplayObject
			{  return _actor;  }
		public function set actor(newDO:DisplayObject):void
		{
			_actor = newDO;
			
			if ( _actor is qb2ProxyObject )
			{
				(_actor as qb2ProxyObject).actualObject = this;
			}
		}
		qb2_friend var _actor:DisplayObject;
		
		public override function clone():qb2Object
			{  return baseClone(super.clone() as qb2Tangible, true, true);  }
			
		qb2_friend function copyProps(source:qb2Tangible, massPropsToo:Boolean = true ):void
		{
			if ( massPropsToo ) // clones will have this true by default, while convertTo*()'s will have it false.
			{
				this._surfaceArea = source._surfaceArea;
				this._mass        = source._mass;
				this._density     = source._density;
			}
			
			//--- Copy velocities.
			if ( (this is qb2IRigidObject) && (source is qb2IRigidObject) )
			{
				this._linearVelocity._x = source._linearVelocity._x;
				this._linearVelocity._y = source._linearVelocity._y;
				this._angularVelocity   = source._angularVelocity;
			}
		}
		
		public virtual function testPoint(point:amPoint2d):Boolean  { return false; }
		
		public virtual function rotateBy(radians:Number, origin:amPoint2d = null):qb2Tangible { return null; }
		
		public function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			if ( this.actor && scaleActor && (this is qb2IRigidObject) )
			{
				var mat:Matrix = this.actor.transform.matrix;
				mat.scale(xValue, yValue);
				this.actor.transform.matrix = mat;
				
				//this.actor.scaleX *= xValue;
				//this.actor.scaleY *= yValue;
			}
			
			return this;
		}
		
		public virtual function translateBy(vector:amVector2d):qb2Tangible { return null; }
		
		public function distanceTo(otherTangible:qb2Tangible, outputVector:amVector2d = null, outputPointThis:amPoint2d = null, outputPointOther:amPoint2d = null, ... excludes):Number
		{
			//--- Do a bunch of checks for whether this is a legal operation in the first place.
			if ( !this.world || !otherTangible.world )
			{
				throw qb2_errors.BAD_DISTANCE_QUERY;
				return NaN;
			}
			if ( this == otherTangible )
			{
				throw qb2_errors.BAD_DISTANCE_QUERY;
				return NaN;
			}
			if ( this is qb2ObjectContainer )
			{
				if ( otherTangible.isDescendantOf(this as qb2ObjectContainer) )
				{
					throw qb2_errors.BAD_DISTANCE_QUERY;
					return NaN;
				}
			}
			if ( otherTangible is qb2ObjectContainer )
			{
				if ( this.isDescendantOf(otherTangible as qb2ObjectContainer) )
				{
					throw qb2_errors.BAD_DISTANCE_QUERY;
					return NaN;
				}
			}
			
			var fixtures1:Array = distanceTo_getFixtures(this, excludes);
			var fixtures2:Array = distanceTo_getFixtures(otherTangible, excludes);
			
			var numFixtures1:int = fixtures1.length;
			var smallest:Number = Number.MAX_VALUE;
			var vec:V2 = null;
			var pointA:amPoint2d = new amPoint2d();
			var pointB:amPoint2d = new amPoint2d();
			
			var din:b2DistanceInput = b2Def.distanceInput;
			var dout:b2DistanceOutput = b2Def.distanceOutput;
			distanceTo_pointShape = distanceTo_pointShape ? distanceTo_pointShape : new b2CircleShape();
			
			for (var i:int = 0; i < numFixtures1; i++) 
			{
				var ithFixture:* = fixtures1[i];
				
				if ( ithFixture is b2Fixture )
				{
					var asFix:b2Fixture = ithFixture as b2Fixture;
					din.proxyA.Set( asFix.m_shape);
					din.transformA.xf = asFix.m_body.GetTransform();
				}
				else
				{
					din.proxyA.Set( distanceTo_pointShape);
					din.transformA.xf = ithFixture as XF;
				}
				
				var numFixtures2:int = fixtures2.length;
				for (var j:int = 0; j < numFixtures2; j++) 
				{
					var jthFixture:* = fixtures2[j];
					
					if ( jthFixture is b2Fixture )
					{
						asFix = jthFixture as b2Fixture;
						din.proxyB.Set( (jthFixture as b2Fixture).m_shape);
						din.transformB.xf = asFix.m_body.GetTransform();
					}
					else
					{
						din.proxyB.Set( distanceTo_pointShape);
						din.transformB.xf = jthFixture as XF;
					}
					
					din.useRadii = true;
					b2Def.simplexCache.count = 0;
					b2Distance();
					var seperation:V2 = dout.pointB.v2.subtract(dout.pointA.v2);
					var distance:Number = seperation.lengthSquared();
					
					if ( distance < smallest )
					{
						smallest = distance;
						vec = seperation;
						pointA.set(dout.pointA.x, dout.pointA.y);
						pointB.set(dout.pointB.x, dout.pointB.y);
					}
				}					
			}
			
			if ( !vec )
			{
				throw qb2_errors.BAD_DISTANCE_QUERY;
				return NaN;
			}
			
			var physScale:Number = worldPixelsPerMeter;
			
			vec.multiplyN(physScale);
			
			if ( outputVector )
			{
				outputVector.set(vec.x, vec.y);
			}
			if ( outputPointThis )
			{
				pointA.scaleBy(physScale, physScale);
				outputPointThis.copy(pointA);
			}
			if ( outputPointOther )
			{
				pointB.scaleBy(physScale, physScale);
				outputPointOther.copy(pointB);
			}
		
			return vec.length();
		}
		
		private static var distanceTo_pointShape:b2CircleShape;
		
		private static function distanceTo_getFixtures(tang:qb2Tangible, excludes:Array):Array
		{
			var returnFixtures:Array = [];
			
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.unshift(tang);
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				for (var k:int = 0; k < excludes.length; k++) 
				{
					var exclude:* = excludes[k];
					if ( exclude is Class )
					{
						var asClass:Class = exclude as Class;
						if ( object is asClass )
						{
							continue;
						}
					}
					else if ( object == exclude )
					{
						continue;
					}
				}
				
				if ( object is qb2Shape )
				{
					var shapeFixtures:Vector.<b2Fixture> = (object as qb2Shape).fixtures;
					
					for (var i:int = 0; i < shapeFixtures.length; i++) 
					{
						returnFixtures.push(shapeFixtures[i]);
					}
				}
				else if ( object is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = object as qb2ObjectContainer;
					var numObjects:int = asContainer._objects.length;
					var hasTangChildren:Boolean = false;
					for (var j:int = 0; j < numObjects; j++) 
					{
						var jth:qb2Object = asContainer._objects[j];
						if ( jth is qb2Tangible )
						{
							queue.push(jth);
							
							hasTangChildren = true;
						}
					}
					
					if ( !hasTangChildren )
					{
						if ( asContainer._bodyB2 )
						{
							returnFixtures.push(asContainer._bodyB2.GetTransform());
						}
						else
						{
							var worldPnt:amPoint2d = asContainer.getWorldPoint(new amPoint2d());
							var xf:XF = new XF();
							xf.p.x = worldPnt.x / asContainer.worldPixelsPerMeter;
							xf.p.y = worldPnt.y / asContainer.worldPixelsPerMeter;
							returnFixtures.push(xf);
						}
					}
				}
			}
			
			return returnFixtures;
		}
		
		public function get density():Number
			{  return _density;  }
		public virtual function set density(value:Number):void { }
		qb2_friend var _density:Number = 0;

		public function get mass():Number
			{  return _mass;  }
		public virtual function set mass(value:Number):void  { }
		qb2_friend var _mass:Number = 0;

		public function get surfaceArea():Number
			{  return _surfaceArea;  }
		qb2_friend var _surfaceArea:Number = 0;
		
		public function get metricSurfaceArea():Number
		{
			const conversion:Number = worldPixelsPerMeter * worldPixelsPerMeter;
			return _surfaceArea/ conversion;
		}
		
		public function get metricDensity():Number
			{  return _mass / metricSurfaceArea;  }
		public function set metricDensity(value:Number):void
			{  density = value / (worldPixelsPerMeter * worldPixelsPerMeter);  }

			
		public function get restitution():Number
			{  return getProperty(qb2_props.T_RESTITUTION) as Number;  }
		public function set restitution(value:Number):void
			{  setProperty(qb2_props.T_RESTITUTION, value);  }
		
		public function get contactCategory():uint
			{  return getProperty(qb2_props.T_CONTACT_CATEGORY) as uint;  }
		public function set contactCategory(bitmask:uint):void
			{  setProperty(qb2_props.T_CONTACT_CATEGORY, bitmask);  }
		
		public function get contactCollidesWith():uint
			{  return getProperty(qb2_props.T_CONTACT_COLLIDES_WITH) as uint;  }
		public function set contactCollidesWith(bitmask:uint):void
			{  setProperty(qb2_props.T_CONTACT_COLLIDES_WITH, bitmask);  }
		
		public function get contactGroupIndex():int
			{  return getProperty(qb2_props.T_CONTACT_GROUP_INDEX) as int; }
		public function set contactGroupIndex(index:int):void
			{  setProperty(qb2_props.T_CONTACT_GROUP_INDEX, index);  }
	
		public function get friction():Number
			{  return getProperty(qb2_props.T_FRICTION) as Number;  }
		public function set friction(value:Number):void
			{  setProperty(qb2_props.T_FRICTION, value);  }
		
		public function get frictionZ():Number
			{  return getProperty(qb2_props.T_FRICTION_Z) as Number;  }
		public function set frictionZ(value:Number):void
			{  setProperty(qb2_props.T_FRICTION_Z, value);  }
		
		public function get linearDamping():Number
			{  return getProperty(qb2_props.T_LINEAR_DAMPING) as Number;  }
		public function set linearDamping(value:Number):void
			{  setProperty(qb2_props.T_LINEAR_DAMPING, value);  }
		
		public function get angularDamping():Number
			{  return getProperty(qb2_props.T_ANGULAR_DAMPING) as Number;  }
		public function set angularDamping(value:Number):void
			{  setProperty(qb2_props.T_ANGULAR_DAMPING, value);  }
		
		
		
		
		
		public function get isGhost():Boolean
			{  return _flags & qb2_flags.T_IS_GHOST ? true : false;  }
		public function set isGhost(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.T_IS_GHOST);
			else
				turnFlagOff(qb2_flags.T_IS_GHOST);
		}
		
		public function get isKinematic():Boolean
			{  return _flags & qb2_flags.T_IS_KINEMATIC ? true : false;  }
		public function set isKinematic(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.T_IS_KINEMATIC);
			else
				turnFlagOff(qb2_flags.T_IS_KINEMATIC);
		}
	
		public function get hasFixedRotation():Boolean
			{  return _flags & qb2_flags.T_HAS_FIXED_ROTATION ? true : false;  }
		public function set hasFixedRotation(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.T_HAS_FIXED_ROTATION);
			else
				turnFlagOff(qb2_flags.T_HAS_FIXED_ROTATION);
		}
		
		public function get isBullet():Boolean
			{  return _flags & qb2_flags.T_IS_BULLET ? true : false;  }
		public function set isBullet(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.T_IS_BULLET);
			else
				turnFlagOff(qb2_flags.T_IS_BULLET);
		}
		
		public function get allowSleeping():Boolean
			{  return _flags & qb2_flags.T_ALLOW_SLEEPING ? true : false;  }
		public function set allowSleeping(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.T_ALLOW_SLEEPING);
			else
				turnFlagOff(qb2_flags.T_ALLOW_SLEEPING);
		}
		
		public function get sleepingWhenAdded():Boolean
			{  return _flags & qb2_flags.T_SLEEPING_WHEN_ADDED ? true : false;  }
		public function set sleepingWhenAdded(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.T_SLEEPING_WHEN_ADDED);
			else
				turnFlagOff(qb2_flags.T_SLEEPING_WHEN_ADDED);
		}
		
		public function get isDebugDraggable():Boolean
			{  return _flags & qb2_flags.T_IS_DEBUG_DRAGGABLE ? true : false;  }
		public function set isDebugDraggable(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.T_IS_DEBUG_DRAGGABLE);
			else
				turnFlagOff(qb2_flags.T_IS_DEBUG_DRAGGABLE);
		}

		
		
		public function get isSleeping():Boolean
		{
			if ( _bodyB2 )
				return !_bodyB2.IsAwake();
			else if ( _ancestorBody )
				return _ancestorBody.isSleeping;
			else
				return true;
		}
			
		public function putToSleep():void
			{  if ( _bodyB2 )  _bodyB2.SetAwake(false);  }

		public function wakeUp():void
		{
			if ( _bodyB2 )
				_bodyB2.SetAwake(true);
			else if ( _ancestorBody && _ancestorBody._bodyB2 )
				_ancestorBody._bodyB2.SetAwake(true);
		}
		
		public virtual function get centerOfMass():amPoint2d { return null; }  // implemented by qb2Shape, qb2Body, and qb2Group all seperately
		
		public function applyImpulse(atPoint:amPoint2d, impulseVector:amVector2d):void
		{
			if ( _bodyB2 )
			{
				_bodyB2.ApplyImpulse(new V2(impulseVector.x, impulseVector.y), new V2(atPoint.x / worldPixelsPerMeter, atPoint.y / worldPixelsPerMeter));
				_linearVelocity._x = _bodyB2.m_linearVelocity.x;
				_linearVelocity._y = _bodyB2.m_linearVelocity.y;
			}
			else if ( _ancestorBody && _ancestorBody._bodyB2 )
				_ancestorBody.applyImpulse(_parent.getWorldPoint(atPoint), _parent.getWorldVector(impulseVector));
		}
		
		public function applyForce(atPoint:amPoint2d, forceVector:amVector2d):void
		{
			if ( _bodyB2 )
				_bodyB2.ApplyForce(new V2(forceVector.x, forceVector.y), new V2(atPoint.x / worldPixelsPerMeter, atPoint.y / worldPixelsPerMeter));
			else if ( _ancestorBody && _ancestorBody._bodyB2 )
				_ancestorBody.applyForce(_parent.getWorldPoint(atPoint), _parent.getWorldVector(forceVector));
		}
		
		public function applyTorque(torque:Number):void
		{
			if ( _bodyB2 )
				_bodyB2.ApplyTorque(torque);
		}
			
		public function getWorldPoint(localPoint:amPoint2d, overrideWorldSpace:qb2Tangible = null):amPoint2d
		{
			var worldPnt:amPoint2d = new amPoint2d(localPoint._x, localPoint._y);
			
			var currParent:qb2Tangible = this;
			while ( currParent && currParent != overrideWorldSpace )
			{
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk up the tree.
				if ( currParent is qb2IRigidObject )
				{
					worldPnt._x += currParent._position._x;
					worldPnt._y += currParent._position._y;
					
					var sinRad:Number = Math.sin(currParent._rotation);
					var cosRad:Number = Math.cos(currParent._rotation);
					var newVertX:Number = currParent._position._x + cosRad * (worldPnt._x - currParent._position._x) - sinRad * (worldPnt._y - currParent._position._y);
					var newVertY:Number = currParent._position._y + sinRad * (worldPnt._x - currParent._position._x) + cosRad * (worldPnt._y - currParent._position._y);
					
					worldPnt._x = newVertX;
					worldPnt._y = newVertY;
				}
				
				currParent = currParent._parent;
			}
			
			return worldPnt;
		}

		public function getLocalPoint(worldPoint:amPoint2d, overrideWorldSpace:qb2Tangible = null):amPoint2d
		{
			var localPnt:amPoint2d = new amPoint2d(worldPoint._x, worldPoint._y);
			
			var spaceList:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
			var currParent:qb2Tangible = this;
			
			while ( currParent && currParent != overrideWorldSpace )
			{
				spaceList.unshift(currParent);
				
				currParent = currParent._parent;
			}
			
			for (var i:int = 0; i < spaceList.length; i++) 
			{
				var space:qb2Tangible = spaceList[i];
				
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk down the tree.
				if ( space is qb2IRigidObject )
				{
					localPnt._x -= space._position._x;
					localPnt._y -= space._position._y;
					
					var sinRad:Number = Math.sin(-space._rotation);
					var cosRad:Number = Math.cos(-space._rotation);
					var newVertX:Number = cosRad * (localPnt._x) - sinRad * (localPnt._y);
					var newVertY:Number = sinRad * (localPnt._x) + cosRad * (localPnt._y);
					
					localPnt._x = newVertX;
					localPnt._y = newVertY;
				}
			}
			
			return localPnt;
		}

		public function getWorldVector(localVector:amVector2d, overrideWorldSpace:qb2Tangible = null):amVector2d
		{
			var worldVector:amVector2d = new amVector2d(localVector._x, localVector._y);
			
			var currParent:qb2Tangible = this;
			while ( currParent && currParent != overrideWorldSpace )
			{
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk up the tree.
				if ( currParent is qb2IRigidObject )
				{
					var sinRad:Number = Math.sin(currParent._rotation);
					var cosRad:Number = Math.cos(currParent._rotation);
					var newVecX:Number = worldVector._x * cosRad - worldVector._y * sinRad;
					var newVecY:Number = worldVector._x * sinRad + worldVector._y * cosRad;
					
					worldVector._x = newVecX;
					worldVector._y = newVecY;
				}
				
				currParent = currParent._parent;
			}
			
			return worldVector;
		}

		public function getLocalVector(worldVector:amVector2d, overrideWorldSpace:qb2Tangible = null):amVector2d
		{
			var localVector:amVector2d = new amVector2d(worldVector._x, worldVector._y);
			
			var spaceList:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
			var currParent:qb2Tangible = this;
			
			while ( currParent && currParent != overrideWorldSpace )
			{
				spaceList.unshift(currParent);
				
				currParent = currParent._parent;
			}
			
			for (var i:int = 0; i < spaceList.length; i++) 
			{
				var space:qb2Tangible = spaceList[i];
				
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk down the tree.
				if ( space is qb2IRigidObject )
				{
					var sinRad:Number = Math.sin(-space._rotation);
					var cosRad:Number = Math.cos(-space._rotation);
					var newVecX:Number = localVector._x * cosRad - localVector._y * sinRad;
					var newVecY:Number = localVector._x * sinRad + localVector._y * cosRad;
					
					localVector._x = newVecX;
					localVector._y = newVecY;
				}
			}
			
			return localVector;
		}
		
		public function getWorldRotation(localRotation:Number, overrideWorldSpace:qb2Tangible = null):Number
		{
			var worldRotation:Number = localRotation;
			
			var currParent:qb2Tangible = this;
			while ( currParent && currParent != overrideWorldSpace )
			{
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk up the tree.
				if ( currParent is qb2IRigidObject )
				{
					worldRotation += currParent._rotation;
				}
				
				currParent = currParent._parent;
			}
			
			return worldRotation;
		}

		public function getLocalRotation(worldRotation:Number, overrideWorldSpace:qb2Tangible = null):Number
		{
			var localRotation:Number = worldRotation;
			
			var spaceList:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
			var currParent:qb2Tangible = this;
			
			while ( currParent && currParent != overrideWorldSpace )
			{
				spaceList.unshift(currParent);
				currParent = currParent._parent;
			}
			
			for (var i:int = 0; i < spaceList.length; i++) 
			{
				var space:qb2Tangible = spaceList[i];
				
				//--- NOTE: since qb2Groups don't have transforms, they can be skipped in our walk down the tree.
				if ( space is qb2IRigidObject )
				{
					localRotation -= space._rotation;
				}
			}
			
			return localRotation;
		}
		
		public function getBoundBox(worldSpace:qb2Tangible = null):amBoundBox2d
		{
			var box:amBoundBox2d = new amBoundBox2d();
			var boxSet:Boolean = false;
			
			var queue:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			queue.unshift(this);
			
			while ( queue.length )
			{
				var tang:qb2Tangible = queue.shift();
				
				if ( tang is qb2Shape )
				{
					if ( tang is qb2CircleShape )
					{
						var asCircleShape:qb2CircleShape = tang as qb2CircleShape;
						var circlePoint:amPoint2d = asCircleShape.parent.getWorldPoint(asCircleShape.position, worldSpace);
						
						if ( !boxSet )
						{
							box.min = circlePoint;
							box.max.copy(box.min);
							box.swell(asCircleShape.radius);
							boxSet = true;
						}
						else
						{
							box.expandToPoint(circlePoint, asCircleShape.radius);
						}
					}
					else if ( tang is qb2PolygonShape )
					{
						var asPolygonShape:qb2PolygonShape = tang as qb2PolygonShape;
						
						for (var i:int = 0; i < asPolygonShape.numVertices; i++) 
						{
							var ithVertex:amPoint2d = asPolygonShape.parent.getWorldPoint(asPolygonShape.getVertexAt(i), worldSpace);
							
							if ( !boxSet )
							{
								box.min = ithVertex
								box.max.copy(box.min);
								boxSet = true;
							}
							else
							{
								box.expandToPoint(ithVertex);
							}
						}
					}
				}
				else if ( tang is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = tang as qb2ObjectContainer;
					
					for ( i = 0; i < asContainer._objects.length; i++) 
					{
						var ithObject:qb2Object = asContainer._objects[i];
						
						if ( ithObject is qb2Tangible )
						{
							queue.unshift(ithObject as qb2Tangible);
						}
					}
				}
			}
			
			if ( !boxSet && (this is qb2Body) )
			{
				var worldPos:amPoint2d = getWorldPoint( (this as qb2Body)._position, worldSpace);
				box.setByCopy(worldPos, worldPos);
			}
			
			return box;
		}
		
		public function getConvexHull(worldSpace:qb2Tangible = null):amPolygon2d
		{
			return null;
		}
		
		public function getBoundCircle(worldSpace:qb2Tangible = null):amBoundCircle2d
		{
			var circle:amBoundCircle2d = new amBoundCircle2d();
			var circleSet:Boolean = false;
			
			var queue:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			queue.unshift(this);
			
			var points:Dictionary = new Dictionary(true);
			
			while ( queue.length )
			{
				var tang:qb2Tangible = queue.shift();
				
				if ( tang is qb2Shape )
				{
					if ( tang is qb2CircleShape )
					{
						var asCircleShape:qb2CircleShape = tang as qb2CircleShape;
						var circlePoint:amPoint2d = asCircleShape.parent.getWorldPoint(asCircleShape.position, worldSpace);
						points[circlePoint] = asCircleShape.radius;
					}
					else if ( tang is qb2PolygonShape )
					{
						var asPolygonShape:qb2PolygonShape = tang as qb2PolygonShape;
						
						for (var i:int = 0; i < asPolygonShape.numVertices; i++) 
						{
							var ithVertex:amPoint2d = asPolygonShape.parent.getWorldPoint(asPolygonShape.getVertexAt(i), worldSpace);
							points[ithVertex] = 0;
						}
					}
				}
				else if ( tang is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = tang as qb2ObjectContainer;
					
					for ( i = 0; i < asContainer._objects.length; i++) 
					{
						var ithObject:qb2Object = asContainer._objects[i];
						
						if ( ithObject is qb2Tangible )
						{
							queue.push(ithObject as qb2Tangible);
						}
					}
				}
			}
			
			return circle;
		}
		
		public function getLinearVelocityAtPoint(point:amPoint2d):amVector2d
		{
			if ( _bodyB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var pointB2:V2 = new V2(point.x / conversion, point.y / conversion);
				var velVecB2:V2 = _bodyB2.GetLinearVelocityFromWorldPoint(pointB2);
				return new amVector2d(velVecB2.x, velVecB2.y);
			}
			else if ( _ancestorBody )
			{
				if ( _ancestorBody._bodyB2 )
				{
					return _ancestorBody.getLinearVelocityAtPoint(_parent.getWorldPoint(point));
				}
				else
				{
					return new amVector2d();
				}
			}
			else if ( this is qb2Group )
			{
				var asGroup:qb2Group = this as qb2Group;
				var rigids:Vector.<qb2IRigidObject> = asGroup.getRigidsAtPoint(point);
				if ( rigids )
				{
					var highestRigid:qb2IRigidObject = rigids[rigids.length - 1];
					return highestRigid.getLinearVelocityAtPoint(point);
				}
			}
			
			return new amVector2d();
		}
		
		public function getLinearVelocityAtLocalPoint(point:amPoint2d):amVector2d
		{
			if ( _bodyB2 )
			{
				var conversion:Number = worldPixelsPerMeter;
				var pointB2:V2 = new V2(point.x / conversion, point.y / conversion);
				var velVecB2:V2 = _bodyB2.GetLinearVelocityFromLocalPoint(pointB2);
				return new amVector2d(velVecB2.x, velVecB2.y);
			}
			else if ( _ancestorBody )
			{
				if ( _ancestorBody._bodyB2 )
				{
					var ancestorBodyLocalPoint:amPoint2d = _ancestorBody.getLocalPoint(this.getWorldPoint(point));
					return _ancestorBody.getLinearVelocityAtLocalPoint(ancestorBodyLocalPoint);
				}
				else
				{
					return new amVector2d();
				}
			}
			else if ( this is qb2Group )
			{
				var asGroup:qb2Group = this as qb2Group;
				var rigids:Vector.<qb2IRigidObject> = asGroup.getRigidsAtPoint(point);
				if ( rigids )
				{
					var highestRigid:qb2IRigidObject = rigids[rigids.length - 1];
					return highestRigid.getLinearVelocityAtPoint(point);
				}
			}
			
			return new amVector2d();
		}
		
		qb2_friend function populateTerrainsBelowThisTang():void
		{
			var globalList:Vector.<qb2Terrain> = _world._globalTerrainList;
			
			_terrainsBelowThisTang = null;
			
			if ( globalList )
			{
				var numGlobalTerrains:int = globalList.length;
			
				for (var i:int = numGlobalTerrains-1; i >= 0; i-- ) 
				{
					var ithTerrain:qb2Terrain = globalList[i];
					
					if ( this == ithTerrain || this.isDescendantOf(ithTerrain) )  continue;
					
					if ( this.isAbove(ithTerrain) )
					{
						if ( !_terrainsBelowThisTang )
						{
							_terrainsBelowThisTang = new Vector.<qb2Terrain>();
						}
						
						_terrainsBelowThisTang.unshift(ithTerrain);
						
						if ( ithTerrain.ubiquitous )
						{
							break; // ubiquitous terrains cover up all other terrains beneath them, so we can move on.
						}
					}
					else
					{
						break; // all subsequent terrains will be over this shape, so we can move on.
					}
				}
			}
			
			_world._terrainRevisionDict[this] = _world._globalTerrainRevision;
		}
		qb2_friend var _terrainsBelowThisTang:Vector.<qb2Terrain>;
		
		/*public virtual function shatterRadial(focalPoint:amPoint2d, numRadialFractures:uint = 10, numRandomFractures:uint = 5, randomRadials:Boolean = true):Vector.<qb2Tangible>  {  return null;  }
		
		public virtual function shatterRandom(numFractures:uint = 10):Vector.<qb2Tangible>  { return null; }
		
		public virtual function slice(laser:amLine2d):Vector.<qb2Tangible>  {  return null;  }
		
		public virtual function sliceUp(knives:Vector.<amLine2d>):Vector.<qb2Tangible>  {  return null;  }*/
		
		protected override function update():void
		{
			//--- NOTE: qb2Object doesn't implement update(), so there's no reason to call it.
			
			if ( effects )
			{
				for (var i:int = 0; i < effects.length; i++) 
				{
					effects[i].apply(this);
				}
			}
		}
		
		
		qb2_friend function drawDebugExtras(graphics:Graphics):void
		{
			//--- Draw positions for rigid objects.
			if ( (this is qb2IRigidObject) && (qb2_debugDrawSettings.flags & qb2_debugDrawFlags.POSITIONS) )
			{
				var rigid:qb2IRigidObject = this as qb2IRigidObject;
				var point:amPoint2d = _parent ? _parent.getWorldPoint(rigid.position) : rigid.position;
				graphics.lineStyle(qb2_debugDrawSettings.lineThickness, debugOutlineColor, qb2_debugDrawSettings.outlineAlpha);
				point.draw(graphics, qb2_debugDrawSettings.pointRadius, true);
			}
		
			var flags:uint = qb2_debugDrawSettings.flags;
			var depth:uint = 0;
			
			var currParent:qb2Tangible = this;
			while ( currParent != _world )
			{
				depth++;
				currParent = currParent.parent;
			}
			
			if ( flags & qb2_debugDrawFlags.BOUND_BOXES )
			{
				if ( amUtils.isWithin(depth, qb2_debugDrawSettings.boundBoxStartDepth, qb2_debugDrawSettings.boundBoxEndDepth) )
				{
					graphics.lineStyle(qb2_debugDrawSettings.lineThickness, qb2_debugDrawSettings.boundBoxColor, qb2_debugDrawSettings.boundBoxAlpha);
					getBoundBox().draw(graphics);
				}
			}
			
			if ( flags & qb2_debugDrawFlags.BOUND_CIRCLES )
			{
				if ( amUtils.isWithin(depth, qb2_debugDrawSettings.boundCircleStartDepth, qb2_debugDrawSettings.boundCircleEndDepth) )
				{
					graphics.lineStyle(qb2_debugDrawSettings.lineThickness, qb2_debugDrawSettings.boundCircleColor, qb2_debugDrawSettings.boundCircleAlpha);
					getBoundCircle().draw(graphics);
				}
			}
			
			if ( flags & qb2_debugDrawFlags.CENTROIDS )
			{
				if ( amUtils.isWithin(depth, qb2_debugDrawSettings.centroidStartDepth, qb2_debugDrawSettings.centroidEndDepth) )
				{
					graphics.lineStyle(qb2_debugDrawSettings.lineThickness, qb2_debugDrawSettings.centroidColor, qb2_debugDrawSettings.centroidAlpha);
					var centroid:amPoint2d = centerOfMass;
					if( centroid )  centroid.draw(graphics, qb2_debugDrawSettings.pointRadius, true);
				}
			}
		}
		
		protected function get debugOutlineColor():uint
		{
			if ( isKinematic )
				return qb2_debugDrawSettings.kinematicOutlineColor;
			else
				return mass == 0 ? qb2_debugDrawSettings.staticOutlineColor : qb2_debugDrawSettings.dynamicOutlineColor;
		}
		
		protected function get debugFillColor():uint
		{
			if ( debugFillColorStack.length )
			{
				return debugFillColorStack[0];
			}
			else
			{
				if ( isKinematic )
					return qb2_debugDrawSettings.kinematicFillColor;
				else
					return mass == 0 ? qb2_debugDrawSettings.staticFillColor : qb2_debugDrawSettings.dynamicFillColor;
			}
		}
		
		protected static const debugFillColorStack:Vector.<uint> = new Vector.<uint>;
		
		private static function rigid_shouldTransform(oldPos:amPoint2d, newPos:amPoint2d, oldRot:Number, newRot:Number):Boolean
		{
			//--- Return true if oldPos and newPos reference the same object, cause in this case it's likely that pointUpdated was invoked, and _position was changed.
			return !oldPos.equals(newPos, diffTol) || !amUtils.isWithin(oldRot, newRot - rotTol, newRot + rotTol);
		}
		
		qb2_friend function rigid_makeBodyB2(theWorld:qb2World):void
		{
			if ( theWorld.processingBox2DStuff )
			{
				theWorld.addDelayedCall(this, rigid_makeBodyB2, theWorld);
				return;
			}
			
			var rigid:qb2IRigidObject = this as qb2IRigidObject;
			var conversion:Number = theWorld._pixelsPerMeter;
			
			//--- Populate body def.  
			var bodDef:b2BodyDef  = b2Def.body;
			bodDef.allowSleep     = this.allowSleeping;
			bodDef.fixedRotation  = this.hasFixedRotation;
			bodDef.bullet         = this.isBullet;
			bodDef.awake          = !this.sleepingWhenAdded;
			bodDef.linearDamping  = this.linearDamping;
			bodDef.angularDamping = this.angularDamping;
			//bodDef.type         = NOTE: type is taken care of in recomputeB2Mass, which will be called after this function some time.
			bodDef.position.x     = rigid.position.x / conversion;
			bodDef.position.y     = rigid.position.y / conversion;
			bodDef.angle          = rigid.rotation;
			
			_bodyB2 = theWorld._worldB2.CreateBody(bodDef);
			_bodyB2.m_linearVelocity.x = rigid.linearVelocity.x;
			_bodyB2.m_linearVelocity.y = rigid.linearVelocity.y;
			_bodyB2.m_angularVelocity  = rigid.angularVelocity;
			_bodyB2.SetUserData(this);
		}
		
		qb2_friend function rigid_destroyBodyB2():void
		{
			_bodyB2.SetUserData(null);
			
			if ( _world.processingBox2DStuff )
			{
				_world.addDelayedCall(this, _world._worldB2.DestroyBody, _bodyB2);
			}
			else
			{
				_world._worldB2.DestroyBody(_bodyB2);
			}
			
			_bodyB2 = null;
		}
		
		qb2_friend virtual function updateFrictionJoints():void
		{
		}
		
		qb2_friend function rigid_recomputeBodyB2Mass():void
		{
			var thisIsKinematic:Boolean = this.isKinematic;
			
			//--- Box2D gets pissed sometimes if you change a body from dynamic to static/kinematic within a contact callback.
			//--- So whenever this happen's the call is delayed until after the physics step, which shouldn't affect the simulation really.
			var theWorld:qb2World = qb2World.worldDict[_bodyB2.m_world] as qb2World;
			var changingToZeroMass:Boolean = !_mass || thisIsKinematic;
			if ( _bodyB2.GetType() == b2Body.b2_dynamicBody && changingToZeroMass && theWorld.processingBox2DStuff )
			{
				theWorld.addDelayedCall(null, this.rigid_recomputeBodyB2Mass);
				return;
			}
			
			_bodyB2.SetType(thisIsKinematic ? b2Body.b2_kinematicBody : (_mass ? b2Body.b2_dynamicBody : b2Body.b2_staticBody));
			//_bodyB2.ResetMassData(); // this is called by SetType(), so was redundant, but i'm still afraid that commenting it out would break something, so it's here for now.
			
			//--- The mechanism by which we save some costly b2Body::ResetMassData() calls (by setting the body to static until all shapes are done adding),
			//--- causes the body's velocities to be zeroed out, so here we just set them back to what they were.
			if ( _bodyB2.m_type != b2Body.b2_staticBody )
			{
				_bodyB2.m_linearVelocity.x = _linearVelocity._x;
				_bodyB2.m_linearVelocity.y = _linearVelocity._y;
				_bodyB2.m_angularVelocity  = _angularVelocity;
			}
		}
		
		qb2_friend virtual function rigid_flushShapes():void  {}
		
		qb2_friend function rigid_update():void
		{
			if ( _bodyB2 )
			{
				//--- Clear forces.  This isn't done right after b2World::Step() with b2World::ClearForces(),
				//--- because we would have to go through the whole list of bodies twice.
				_bodyB2.m_force.x = _bodyB2.m_force.y = 0;
				_bodyB2.m_torque = 0;
				
				//--- Get new position/angle.
				const pixPerMeter:Number = worldPixelsPerMeter;
				var newRotation:Number = _bodyB2.GetAngle();
				var newPosition:amPoint2d = new amPoint2d(_bodyB2.GetPosition().x * pixPerMeter, _bodyB2.GetPosition().y * pixPerMeter);
				
				//--- Check if the new transform invalidates the bound box.
				if ( rigid_shouldTransform( _position, newPosition, _rotation, newRotation) )
				{
					if ( this is qb2PolygonShape ) // sloppy, but not doing this in qb2PolygonShape::update() saves a decent amount of double-checking
					{
						(this as qb2PolygonShape).updateFromLagPoints(newPosition, newRotation);
					}
				}
				
				//--- Update the transform, without invoking pointUpdated
				_position._x = newPosition._x;
				_position._y = newPosition._y;
				_rotation    = newRotation;
				
				//--- Update velocities, again without invoking callbacks.
				_linearVelocity._x = _bodyB2.m_linearVelocity.x;
				_linearVelocity._y = _bodyB2.m_linearVelocity.y;
				_angularVelocity   = _bodyB2.m_angularVelocity;
				
				(this as qb2IRigidObject).updateActor();
			}
			
			super.update();
		}
		
		qb2_friend function rigid_setTransform(point:amPoint2d, rotationInRadians:Number):qb2IRigidObject
		{
			var asRigid:qb2IRigidObject = this as qb2IRigidObject;
			
			/*if ( _calledFromPointUpdated || rigid_shouldTransform(_position, point, _rotation, rotationInRadians) )
			{
				invalidateBoundBox();
			}*/
			
			if ( point != _position ) // if e.g. rotateBy or pointUpdated() calls this function, 'point' and '_position' refer to the same point object, otherwise _position must be made to refer to the new object
			{
				if ( _position )  _position.removeEventListener(amUpdateEvent.ENTITY_UPDATED, rigid_pointUpdated);
				_position = point;
				_position.addEventListener(amUpdateEvent.ENTITY_UPDATED, rigid_pointUpdated);
			}
			
			_rotation = rotationInRadians;
			
			if ( _bodyB2 )
			{
				if ( _world.processingBox2DStuff )
				{
					_world.addDelayedCall(this, _bodyB2.SetTransform, new V2(point.x / worldPixelsPerMeter, point.y / worldPixelsPerMeter), rotationInRadians);
				}
				else
				{
					_bodyB2.SetTransform(new V2(point.x / worldPixelsPerMeter, point.y / worldPixelsPerMeter), rotationInRadians);
				}
			}
			
			asRigid.updateActor();
			
			wakeUp();
			
			if ( _ancestorBody ) // (if this object is a child of some body whose only other ancestors are qb2Groups...)
			{
				pushMassFreeze(); // this is only done to prevent b2Body::ResetMassData() from being effectively called more than necessary by setting body type to static.
					rigid_flushShapes();
				popMassFreeze();
				
				//--- Skip the first object (this) in the tree because only parent object's mass properties will be affected.
				updateMassProps(0, 0, true); // we just assume that some kind of center of mass change took place here, even though it didnt *for sure* happen
				
				for (var i:int = 0; i < asRigid.numAttachedJoints; i++) 
				{
					var attachedJoint:qb2Joint = asRigid.getAttachedJointAt(i);
					attachedJoint.correctLocals();
				}
			}		
			
			return asRigid;
		}
		
		qb2_friend function rigid_vectorUpdated(evt:amUpdateEvent):void
		{
			if ( _bodyB2 )
			{
				_bodyB2.m_linearVelocity.x = _linearVelocity.x;
				_bodyB2.m_linearVelocity.y = _linearVelocity.y;
				_bodyB2.SetAwake(true);
			}
		}

		qb2_friend function rigid_pointUpdated(evt:amUpdateEvent):void
		{
			_calledFromPointUpdated = true;
				(this as qb2IRigidObject).setTransform(_position, _rotation);
			_calledFromPointUpdated = false;
		}
		
		qb2_friend function get rigid_attachedMass():Number
		{
			if ( !_attachedJoints )  return 0;
			
			var totalMass:Number = 0;
			var queue:Vector.<qb2IRigidObject> = new Vector.<qb2IRigidObject>();
			queue.unshift(this as qb2IRigidObject);
			var alreadyVisited:Dictionary = new Dictionary(true);
			while ( queue.length )
			{
				var rigid:qb2IRigidObject = queue.shift();
				
				if ( alreadyVisited[rigid] || !rigid.world )  continue;
				
				totalMass += rigid.mass;
				alreadyVisited[rigid] = true;
				
				for (var i:int = 0; i < rigid.numAttachedJoints; i++) 
				{
					var joint:qb2Joint = rigid.getAttachedJointAt(i);
					
					var otherObject:qb2Tangible = joint._object1 == rigid ? joint._object2 : joint._object1;
					
					if ( otherObject )  queue.unshift(otherObject as qb2IRigidObject);
				}
			}
			
			return totalMass - this.mass;
		}
	}
}