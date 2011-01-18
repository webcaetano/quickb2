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
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.utils.Dictionary;
	import QuickB2.*;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	
	use namespace qb2_friend;
	
	[Event(name="addedObject",   type="QuickB2.events.qb2AddRemoveEvent")]
	[Event(name="removedObject", type="QuickB2.events.qb2AddRemoveEvent")]
	[Event(name="descendantAddedObject", type="QuickB2.events.qb2AddRemoveEvent")]
	[Event(name="descendantRemovedObject", type="QuickB2.events.qb2AddRemoveEvent")]	
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2ObjectContainer extends qb2Tangible
	{
		qb2_friend const _objects:Vector.<qb2Object> = new Vector.<qb2Object>();
		
		public function qb2ObjectContainer() 
		{
			if ( (this as Object).constructor == qb2ObjectContainer )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
		}
		
		public function isAncestorOf(possibleDescendant:qb2Object):Boolean
			{  return possibleDescendant.isDescendantOf(this);  }
		
		private static var baseClone_joints:Dictionary = null;
		private static var baseClone_rigids:Dictionary = null;
		
		qb2_friend final override function baseClone(newObject:qb2Tangible, actorToo:Boolean, deep:Boolean):qb2Tangible
		{
			if ( !newObject || (this as Object).constructor != (newObject as Object).constructor)
				throw new Error("newObject's type must match the cloned object's type");
			
			var newContainer:qb2ObjectContainer = newObject as qb2ObjectContainer;
			newContainer.removeAllObjects(); // in case the constructor adds some objects.
			if ( newObject is qb2Body )
				(newObject as qb2Body).setTransform(_position.clone(), _rotation);
			newContainer.copyProps(this);
			
			if ( deep )
			{
				var thisIsCloneRoot:Boolean = false;
				if ( !baseClone_rigids )
				{
					thisIsCloneRoot = true;
					baseClone_rigids = new Dictionary(true);
					baseClone_joints = new Dictionary(true);
				}
				
				var propertyFlushAlreadyCancelled:Boolean = cancelPropertyInheritance;
				cancelPropertyInheritance = true; // this stops all objects being added here from inheriting properties from their ancestors...their properties will be set with qb2Tangible::copyProps(), thus preventing double traversals through the world tree.
				{
					newContainer.pushMassFreeze();
					{
						for (var i:int = 0; i < _objects.length; i++) 
						{
							var object:qb2Object = _objects[i];
							if ( object is qb2Tangible )
							{
								var physObject:qb2Tangible = object as qb2Tangible;
								var clonedObj:qb2Tangible = physObject.clone() as qb2Tangible
								newContainer.addObject(clonedObj);
								
								if ( object is qb2IRigidObject )
								{
									baseClone_rigids[physObject] = clonedObj;
								}
							}
							else if ( object is qb2Joint )
							{
								var joint:qb2Joint = object as qb2Joint;
								var clonedJoint:qb2Joint = joint.clone() as qb2Joint
								newContainer.addObject(clonedJoint);
								
								baseClone_joints[joint] = clonedJoint
							}
							else
							{
								newContainer.addObject(object.clone());
							}
						}
						
						for ( var key:* in baseClone_joints )
						{
							joint = key as qb2Joint;
							var clonedObject1:qb2IRigidObject = baseClone_rigids[joint._object1] as qb2IRigidObject;
							var clonedObject2:qb2IRigidObject = baseClone_rigids[joint._object2] as qb2IRigidObject;
							
							clonedJoint = baseClone_joints[joint];
							
							if ( !clonedJoint._object1 && clonedObject1 )
								clonedJoint.setObject1(clonedObject1, false);
							if ( !clonedJoint._object2 && clonedObject2 )
								clonedJoint.setObject2(clonedObject2, false);
							
							if ( clonedJoint.hasObjectsSet() )
							{
								delete baseClone_joints[joint];
							}
						}
					}
					newContainer.popMassFreeze();
				}
				cancelPropertyInheritance = propertyFlushAlreadyCancelled; // if the property flush was already cancelled, presumably by a deep clone of some ancestor, then the cancelled property flush should remain in effect.
				
				if ( thisIsCloneRoot )
				{
					baseClone_joints = null;
					baseClone_rigids = null;
				}
			}
			
			if ( actorToo && actor )
			{
				newContainer.actor = cloneActor();
			}
			
			return newContainer;
		}
		
		qb2_friend override function setAncestorBody(aBody:qb2Body):void
		{
			_ancestorBody = aBody;
			for (var i:int = 0; i < _objects.length; i++) 
			{
				if ( _objects[i] is qb2Tangible )
				{
					(_objects[i] as qb2Tangible).setAncestorBody(aBody);
				}
			}
		}
		
		qb2_friend override function updateContactReporting(bits:uint):void
		{
			for (var i:int = 0; i < _objects.length; i++) 
			{
				if ( _objects[i] is qb2Tangible )
				{
					var asTang:qb2Tangible = _objects[i] as qb2Tangible;
					asTang.updateContactReporting(bits | asTang._eventFlags);
				}
			}
		}
		
		private static function arrayContainsTangible(someObjects:Vector.<qb2Object>):Boolean
		{
			for (var i:int = 0; i < someObjects.length; i++) 
			{
				if ( someObjects[i] is qb2Tangible )
					return true;
			}
			return false;
		}
		
		private function addMultipleObjectsToArray(someObjects:Vector.<qb2Object>, startIndex:uint):qb2ObjectContainer
		{
			var tangibleFound:Boolean = arrayContainsTangible(someObjects);
			
			if( tangibleFound )  pushMassFreeze();
			{
				var totalArea:Number = 0, totalMass:Number = 0;
				for ( var i:int = 0; i < someObjects.length; i++ )
				{
					var object:qb2Object = someObjects[i];
					addObjectToArray(object, startIndex);
					
					if ( object is qb2Tangible )
					{
						var physObject:qb2Tangible = object as qb2Tangible
						totalArea += physObject._surfaceArea;
						totalMass += physObject._mass;
					}
					
					startIndex++;
				}
			}
			if( tangibleFound )  popMassFreeze();
			
			if ( tangibleFound )
				updateMassProps(totalMass, totalArea);
			
			return this;
		}
		
		private function checkForAddError(object:qb2Object):void
		{
			if ( !object )         throw qb2_errors.ADDING_NULL_ERROR;
			if ( object._parent )  throw qb2_errors.ALREADY_HAS_PARENT_ERROR;
		}
		
		private function addObjectToArray(object:qb2Object, index:uint):void
		{
			checkForAddError(object);
			
			if ( index == _objects.length )
				_objects.push(object);
			else
				_objects.splice(index, 0, object);
			
			object._parent = this;
			
			if ( object is qb2Tangible )
			{
				var physObject:qb2Tangible = object as qb2Tangible;
				if ( !cancelPropertyInheritance ) // only happens when cloning, where properties don't have to be inherited.
				{
					cascadeAncestorProperties(physObject, collectAncestorProperties(physObject));
				}
				
				physObject.addActor();
				
				var theAncestorBody:qb2Body = this._ancestorBody ? this._ancestorBody :  ( this is qb2Body ? this as qb2Body : null);
				if( theAncestorBody )
					physObject.setAncestorBody(theAncestorBody);
			}
			
			if ( _world )  object.make(_world);
			
			if ( eventFlags & ADDED_OBJECT_BIT )
			{
				var evt:qb2AddRemoveEvent = getCachedEvent(qb2AddRemoveEvent.ADDED_OBJECT);
				evt._parentObject = this;
				evt._childObject = object;
				dispatchEvent(evt);
			}
			
			processDescendantEvent(DESCENDANT_ADDED_OBJECT_BIT, getCachedEvent(qb2AddRemoveEvent.DESCENDANT_ADDED_OBJECT) , object);
			
			justAddedObject(object);
		}
		
		private function removeObjectFromArray(index:uint):qb2Object
		{			
			var objectRemoved:qb2Object = _objects.splice(index, 1)[0];
			
			if ( objectRemoved is qb2Tangible )
			{
				var tangible:qb2Tangible = objectRemoved as qb2Tangible
				tangible.removeActor();
				updateMassProps( -tangible._mass, -tangible._surfaceArea);
				
				flushAncestorBody(tangible);
			}
			
			if( _world )  objectRemoved.destroy();
			objectRemoved._parent = null;
			
			if ( eventFlags & REMOVED_OBJECT_BIT )
			{
				var evt:qb2AddRemoveEvent = getCachedEvent(qb2AddRemoveEvent.REMOVED_OBJECT);
				evt._parentObject = this;
				evt._childObject  = objectRemoved;
				dispatchEvent(evt);
			}
			
			processDescendantEvent(DESCENDANT_REMOVED_OBJECT_BIT, getCachedEvent(qb2AddRemoveEvent.DESCENDANT_REMOVED_OBJECT), objectRemoved);
			
			justRemovedObject(objectRemoved);
		
			return objectRemoved;
		}
		
		protected virtual function justAddedObject(object:qb2Object):void   {}
		protected virtual function justRemovedObject(object:qb2Object):void {}
		
		private function processDescendantEvent(bit:uint, cachedEvent:qb2AddRemoveEvent, object:qb2Object):void
		{
			var currParent:qb2ObjectContainer = this.parent;
			while ( currParent )
			{
				if ( currParent.eventFlags & bit )
				{
					var evt:qb2AddRemoveEvent = cachedEvent;
					evt._parentObject = this;
					evt._childObject = object;
					currParent.dispatchEvent(evt);
				}
				
				currParent = currParent.parent;
			}
		}
		
		private static function flushAncestorBody(object:qb2Tangible):void
		{
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.unshift(object);
			
			while ( queue.length )
			{
				var queueObject:qb2Object = queue.shift();
				
				if ( queueObject is qb2Shape )
					(queueObject as qb2Shape).setAncestorBody(null);
				else if ( queueObject is qb2Body )
				{
					var objectAsBody:qb2Body = queueObject as qb2Body;
					objectAsBody._ancestorBody = null; // manually set it here because null shouldn't be propogated down the tree.
					for (var i:int = 0; i < objectAsBody._objects.length; i++) 
					{
						var ithObject:qb2Object = objectAsBody._objects[i];
						
						if ( ithObject is qb2Tangible )
							(ithObject as qb2Tangible).setAncestorBody(objectAsBody);
					}
				}
				else if ( queueObject is qb2Group )
				{
					var objectAsGroup:qb2Group = queueObject as qb2Group;
					objectAsGroup._ancestorBody = null; // manually set it here because null shouldn't be propogated down the tree.
					for (i = 0; i < objectAsGroup._objects.length; i++) 
					{
						ithObject = objectAsGroup._objects[i];
						
						if ( ithObject is qb2Tangible )
							queue.unshift(ithObject as qb2Tangible);
					}
				}
			}
		}
		
		
		public function containsObject(object:qb2Object):Boolean
			{  return _objects.indexOf(object) >= 0;  }
		
		public function getObjectAt(index:uint):qb2Object
			{  return _objects[index];  }

		public function lastObject(minus:uint = 0):qb2Object
			{  return _objects[_objects.length - 1 - minus];  }
		
		public function get numObjects():uint
			{  return _objects.length;  }
			
		public function getObjectIndex(object:qb2Object):int
			{  return _objects.indexOf(object);  }
		
		public function addObjects(someObjects:Vector.<qb2Object>):qb2ObjectContainer
			{  return addMultipleObjectsToArray(someObjects, _objects.length);  }
		
		public function addObject(... oneOrMoreObjects):qb2ObjectContainer
			{  return addMultipleObjectsToArray(Vector.<qb2Object>(oneOrMoreObjects), _objects.length);  }
			
		public function addObjectAt(object:qb2Object, index:uint):qb2ObjectContainer
			{  return addMultipleObjectsToArray(Vector.<qb2Object>([object]), index);  }
			
		public function insertObjectAt(index:uint, ... oneOrMoreObjects):qb2ObjectContainer
			{  return addMultipleObjectsToArray(Vector.<qb2Object>(oneOrMoreObjects), index);  }
		
		public function setObjectAt(index:uint, replacement:qb2Object):qb2Object
		{
			//--- Remove the current shape at this index without recomputing mass yet...don't want to do it twice.
			var objectRemoved:qb2Object;
			pushMassFreeze();
			{
				objectRemoved = removeObjectAt(index);
				insertObjectAt(index, replacement);
			}
			popMassFreeze();
			
			var massDiff:Number = 0, areaDiff:Number = 0;
			
			var physObjectFound:Boolean = false;
			if ( objectRemoved is qb2Tangible )
			{
				var physObject:qb2Tangible = objectRemoved as qb2Tangible;
				massDiff -= physObject._mass;
				areaDiff -= physObject._surfaceArea;
				physObjectFound = true;
			}
			
			if ( replacement is qb2Tangible )
			{
				physObject = replacement as qb2Tangible;
				massDiff += physObject._mass;
				areaDiff += physObject._surfaceArea;
				physObjectFound = true;
			}
		
			if ( physObjectFound )
				updateMassProps(massDiff, areaDiff);
			
			return objectRemoved;
		}
			
		public function setObjectIndex(object:qb2Object, index:uint):qb2ObjectContainer
		{
			var origIndex:int = _objects.indexOf(object);
			_objects.splice(origIndex, 1);
			_objects.splice(index, 0, object);
			return this;
		}
	
		public function removeObject(object:qb2Object):qb2ObjectContainer
		{
			removeObjectAt(_objects.indexOf(object));
			return this;
		}
	
		public function removeObjectAt(index:uint):qb2Object
			{  return removeObjectFromArray(index);  }
		
		public function removeAllObjects():Vector.<qb2Object>
		{
			var toReturn:Vector.<qb2Object>;
			var physObjectFound:Boolean = false;
			
			pushMassFreeze();
			{
				for ( var i:int = 0; i < _objects.length; i++ )
				{
					var startedNumObjects:uint = _objects.length;
					
					if ( !toReturn )
						toReturn = new Vector.<qb2Object>();
					var object:qb2Object = removeObjectAt(i);
					toReturn.push(object);
					
					if ( _objects.length != startedNumObjects ) // if currently processing Box2d stuff, _objects array won't actually be touched.
						i--;
						
					if ( object is qb2Tangible )
						physObjectFound = true;
				}
			}
			popMassFreeze();
			
			if( physObjectFound )
				updateMassProps(-_mass, -_surfaceArea);
			
			return toReturn;
		}
		
		public function explode(preserveVelocities:Boolean = true, addToParent:Boolean = true):Vector.<qb2Object>
		{
			var explodes:Vector.<qb2Object> = this.removeAllObjects();
			
			if ( explodes )
			{
				if ( this is qb2Body )
				{
					var parentBody:qb2Body = this as qb2Body;
					
					for (var i:int = 0; i < explodes.length; i++) 
					{
						if ( explodes[i] is qb2IRigidObject )
						{
							var rigid:qb2IRigidObject = explodes[i] as qb2IRigidObject;
							
							if ( preserveVelocities && !_ancestorBody )
							{
								rigid.linearVelocity.copy(parentBody.getLinearVelocityAtLocalPoint(rigid.position));
							}
							else
							{
								rigid.linearVelocity.zeroOut();
								rigid.angularVelocity = 0;
							}
							
							rigid.position.add(parentBody.position);
							rigid.rotateBy(parentBody.rotation, parentBody.position);
							
						}
						else if( explodes[i] is qb2Group )
						{
							var group:qb2Group = explodes[i] as qb2Group;
							group.translateBy(parentBody.position.asVector());
							group.rotateBy(parentBody.rotation, parentBody.position);
							
							if ( preserveVelocities && !_ancestorBody )
							{
								// do get vel at thing and set velocity of whole group
							}
							else
							{
								group.setAvgLinearVelocity(new amVector2d());
								group.setAvgAngularVelocity(0);
							}
						}
					}
				}
				else if ( (this is qb2Group) && !preserveVelocities && !_ancestorBody ) // have to cancel out velocities
				{
					for ( i = 0; i < explodes.length; i++) 
					{
						if ( explodes[i] is qb2IRigidObject )
						{
							(explodes[i] as qb2IRigidObject).linearVelocity.zeroOut();
							(explodes[i] as qb2IRigidObject).angularVelocity = 0;
						}
						else if ( explodes[i] is qb2Group )
						{
							(explodes[i] as qb2Group).setAvgLinearVelocity(new amVector2d());
							(explodes[i] as qb2Group).setAvgAngularVelocity(0);
						}
					}
				}
				
				if ( _parent )
				{
					if( addToParent )  _parent.addObjects(explodes);
					removeFromParent();
				}
			}
			
			return explodes;
		}
		
		public override function testPoint(point:amPoint2d):Boolean
		{
			const localPoint:amPoint2d = getLocalPoint(point, _parent);
			
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				if ( _objects[i] is qb2Tangible )
				{
					if ( (_objects[i] as qb2Tangible).testPoint(localPoint) )
						return true;
				}
			}
			
			return false;
		}
		
		public override function set density(value:Number):void
		{
			pushMassFreeze();
			{
				for ( var i:int = 0; i < _objects.length; i++ )
				{
					if ( _objects[i] is qb2Tangible )
					{
						(_objects[i] as qb2Tangible).density = value;
					}
				}
			}
			popMassFreeze();
			
			updateMassProps(value * _surfaceArea - _mass, 0);
		}
		
		public override function set mass(value:Number):void
		{
			pushMassFreeze();
			{
				if ( _mass )
				{
					for ( var i:int = 0; i < _objects.length; i++ )
					{
						if ( _objects[i] is qb2Tangible )
						{
							var physObject:qb2Tangible = _objects[i] as qb2Tangible
							var ratio:Number = physObject._mass / _mass;
							physObject.mass = ratio * value;
						}
					}
				}
				else
				{
					var totalDensity:Number = value / _surfaceArea;
					for ( i = 0; i < _objects.length; i++ )
					{
						if ( _objects[i] is qb2Tangible )
						{
							(_objects[i] as qb2Tangible).density = totalDensity;
						}
					}
				}
			}
			popMassFreeze();
			
			updateMassProps(value - _mass, 0);
		}
		
		public override function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible
		{
			super.scaleBy(xValue, yValue, origin, scaleMass, scaleJointAnchors, scaleActor);
			
			if ( scaleJointAnchors && (this is qb2Body) )
				qb2Joint.scaleJointAnchors(xValue, yValue, this as qb2IRigidObject);
				
			var forwardOrigin:amPoint2d = this is qb2Group ? origin : null;
			
			var massDiff:Number = 0, areaDiff:Number = 0;
			pushMassFreeze();
			{
				var subOrigin:amPoint2d = this is qb2Body ? null : origin; // objects belonging to bodies are scaled relative to the body's origin.
				for (var i:int = 0; i < _objects.length; i++) 
				{
					if ( !(_objects[i] is qb2Tangible) )  continue;
					
					var physObject:qb2Tangible = _objects[i] as qb2Tangible;
					var prevMass:Number = physObject._mass;
					var prevArea:Number = physObject._surfaceArea;
					
					physObject.scaleBy(xValue, yValue, forwardOrigin, scaleMass, scaleJointAnchors, scaleActor);
					
					massDiff += physObject._mass - prevMass;
					areaDiff += physObject._surfaceArea - prevArea;
				}
				
				if ( this is qb2IRigidObject )
					(this as qb2IRigidObject).position.scaleBy(xValue, yValue, origin); // eventually calls pointUpdated(), which translates everything.
			}
			popMassFreeze();
			
			updateMassProps(massDiff, areaDiff);
			
			return this;
		}
		
		
		
		public override function draw(graphics:Graphics):void
		{
			for (var i:int = 0; i < _objects.length; i++) 
			{
				_objects[i].draw(graphics);
			}
		}
		
		public override function drawDebug(graphics:Graphics):void
		{
			for (var i:int = 0; i < _objects.length; i++) 
			{
				if ( _objects[i].drawsDebug )
				{
					_objects[i].drawDebug(graphics);
				}
				
				if ( _objects[i] is qb2Tangible )
				{
					(_objects[i] as qb2Tangible).drawDebugExtras(graphics);
				}
			}
		}
		
		public override function get centerOfMass():amPoint2d
		{
			var totMass:Number = 0;
			var totX:Number = 0, totY:Number = 0;
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = _objects[i] as qb2Tangible;
				var ithMass:Number = physObject.mass;
				var ithCenter:amPoint2d = getWorldPoint(physObject.centerOfMass, this.parent);
				
				if ( !ithCenter )  continue;
				
				totX += ithCenter.x * ithMass;
				totY += ithCenter.y * ithMass;
				totMass += ithMass;
			}
			
			return totMass ? new amPoint2d(totX / totMass, totY / totMass) : new amPoint2d();
		}
		
		qb2_friend override function rigid_flushShapes():void
		{
			for (var i:int = 0; i < _objects.length; i++) 
			{
				if( _objects[i] is qb2Tangible )
				(_objects[i] as qb2Tangible).rigid_flushShapes();
			}
		}
		
		
		
		public function getAllRigids():Vector.<qb2IRigidObject>
		{
			if ( !_objects.length )  return null;
			
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
		
			var toReturn:Vector.<qb2IRigidObject> = null;
			queue.unshift(this);
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible
				
				if ( physObject is qb2ObjectContainer )
				{
					var container:qb2ObjectContainer = physObject as qb2ObjectContainer;
					for ( var i:int = 0; i < container.numObjects; i++ )
					{
						queue.unshift(container.getObjectAt(i));
					}
				}
				else if ( physObject is qb2IRigidObject )
				{
					if ( !toReturn )
						toReturn = new Vector.<qb2IRigidObject>();
						
					toReturn.push(physObject as qb2IRigidObject);
				}
			}
			
			return toReturn;
		}
		
		public function getRigidsAtPoint(point:amPoint2d, limit:uint = uint.MAX_VALUE, searchDirection:int = -1, dynamicOnly:Boolean = true):Vector.<qb2IRigidObject>
		{
			var toReturn:Vector.<qb2IRigidObject> = null;
			
			if ( !_objects.length || limit < 1 )  return toReturn;
	
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.unshift(this);
			var count:uint = 0;
			while ( queue.length )
			{
				var object:qb2Object = queue.shift();
				
				if ( !(object is qb2Tangible) )  continue;
				
				var tang:qb2Tangible = object as qb2Tangible;
				
				if ( (!tang.mass || tang.isKinematic) && dynamicOnly )  continue;
				
				if ( tang is qb2Group )
				{
					var group:qb2Group = tang as qb2Group;
					if ( searchDirection >= 0 )
					{
						for ( var i:int = group.numObjects-1; i >= 0; i--)
						{
							queue.unshift(group.getObjectAt(i));
						}
					}
					else
					{
						for ( i =0; i < group.numObjects; i++)
						{
							queue.unshift(group.getObjectAt(i));
						}
					}
				}
				else if ( tang is qb2IRigidObject )
				{
					if ( tang.testPoint(point) )
					{
						if ( !toReturn )  toReturn = new Vector.<qb2IRigidObject>();
						
						toReturn.push(tang);
						count++;
						
						if ( count >= limit )  return toReturn;
					}
				}
			}
			
			return toReturn;
		}
		
		/*public function getClosestRigid(toPoint:amPoint2d, includeStaticObjects:Boolean = false, useCentersOfMass:Boolean = true):qb2IRigidObject
		{
			var closest:qb2IRigidObject = null;
			var closestDist:Number = Number.MAX_VALUE;
		
			for ( var i:int = 0; i < _objects.length; i++ )
			{
				var object:qb2Object = _objects[i];
				
				if ( !(object is qb2Tangible) )  continue;
				
				var physObject:qb2Tangible = object as qb2Tangible;
				var candidate:qb2IRigidObject = null;
				
				if ( physObject is qb2ObjectContainer )
				{
					var container:qb2ObjectContainer = object as qb2ObjectContainer;
					candidate = container.getClosestRigid(toPoint, includeStaticObjects, useCentersOfMass) as qb2IRigidObject;
					if ( !candidate )  continue;
				}
				else if ( physObject is qb2IRigidObject )
				{
					var rigid:qb2IRigidObject = physObject as qb2IRigidObject;
					if ( !includeStaticObjects && physObject.mass == 0 )  continue;
					
					candidate = rigid;
				}
				
				var tangPos:amPoint2d = useCentersOfMass && physObject.mass ? (candidate as qb2Tangible).centerOfMass : candidate.position;
				var dist:Number = tangPos.distanceTo(toPoint);
				if ( dist < closestDist )
				{
					dist = closestDist;
					closest = candidate;
				}
			}
			
			return closest;
		}*/
	}
}