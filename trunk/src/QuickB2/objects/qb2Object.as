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

package QuickB2.objects 
{
	import As3Math.geo2d.amBoundArea2d;
	import As3Math.geo2d.amBoundBox2d;
	import Box2DAS.Common.V2;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.Dictionary;
	import QuickB2.*;
	import QuickB2.debugging.qb2DebugTraceSettings;
	import QuickB2.events.*;
	import QuickB2.misc.qb2_flags;
	import QuickB2.objects.joints.*;
	import QuickB2.objects.tangibles.*;
	use namespace qb2_friend;
	
	[Event(name="preUpdate",        type="QuickB2.events.qb2UpdateEvent")]
	[Event(name="postUpdate",       type="QuickB2.events.qb2UpdateEvent")]
	
	[Event(name="addedToWorld",     type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="removedFromWorld", type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="indexChanged",     type="QuickB2.events.qb2ContainerEvent")]
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Object extends qb2EventDispatcher
	{
		public var identifier:String = "";
		
		public function qb2Object()
		{
			if ( (this as Object).constructor == qb2Object )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
			
			turnFlagOn(qb2_flags.O_JOINS_IN_DEBUG_DRAWING | qb2_flags.O_JOINS_IN_DEEP_CLONING | qb2_flags.O_JOINS_IN_UPDATE_CHAIN, true);
			
			if ( !eventsInitialized )
			{
				initializeEvents();
			}
		}
		
		qb2_friend var _ownershipFlagsForProperties:uint  = 0;
		qb2_friend var _ownershipFlagsForBooleans:uint    = 0;
		
		public function get flags():uint
			{  return _flags;  }
		qb2_friend var _flags:uint = 0;
		
		public final function turnFlagOff(flag:uint, passive:Boolean = false):qb2Object
		{
			_flags &= ~flag;
			
			if ( passive )
			{
				_ownershipFlagsForBooleans &= ~flag;
				flagsChanged(flag);
			}
			else
			{
				cascadeFlags(this, flag);
			}
			
			return this;
		}
		
		public final function turnFlagOn(flag:uint, passive:Boolean = false):qb2Object
		{
			_flags |= flag;
			
			if ( passive )
			{
				_ownershipFlagsForBooleans &= ~flag;
				flagsChanged(flag);
			}
			else
			{
				cascadeFlags(this, flag);
			}
			
			return this;
		}
		
		public final function isFlagOn(flag:uint):Boolean
		{
			return _flags & flag ? true : false;
		}
		
		public final function getProperty(propertyName:String):*
		{
			return _propertyMap[propertyName];
		}
		
		public final function setProperty(propertyName:String, value:*, passive:Boolean = false):qb2Object
		{
			//--- Check if this property has been registered yet by any object.
			if ( !_propertyBits[propertyName] )
			{
				if ( !_currPropertyBit )
				{
					throw qb2_errors.NUMBER_PROPERTY_SLOTS_FULL;
				}
				
				_propertyBits[propertyName] = _currPropertyBit;
				_currPropertyBit = _currPropertyBit << 1;
			}
			
			if ( passive )
			{
				_propertyMap[propertyName] = value;
				_ownershipFlagsForProperties &= ~_propertyBits[propertyName];
				propertyChanged(propertyName, value);
			}
			else
			{
				cascadeProperty(this, propertyName, value);
			}
			
			return this;
		}
		
		private var _propertyMap:Object = { };
		
		private static var _propertyBits:Object = { };
		private static var _currPropertyBit:uint = 0x00000001;
		
		public function get joinsInDeepCloning():Boolean
			{  return _flags & qb2_flags.O_JOINS_IN_DEEP_CLONING ? true : false;  }
		public function set joinsInDeepCloning(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.O_JOINS_IN_DEEP_CLONING);
			else
				turnFlagOff(qb2_flags.O_JOINS_IN_DEEP_CLONING);
		}
		
		public function get joinsInDebugDrawing():Boolean
			{  return _flags & qb2_flags.O_JOINS_IN_DEBUG_DRAWING ? true : false;  }
		public function set joinsInDebugDrawing(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.O_JOINS_IN_DEBUG_DRAWING);
			else
				turnFlagOff(qb2_flags.O_JOINS_IN_DEBUG_DRAWING);
		}
		
		public function get joinsInUpdateChain():Boolean
			{  return _flags & qb2_flags.O_JOINS_IN_UPDATE_CHAIN ? true : false;  }
		public function set joinsInUpdateChain(bool:Boolean):void
		{
			if ( bool )
				turnFlagOn(qb2_flags.O_JOINS_IN_UPDATE_CHAIN);
			else
				turnFlagOff(qb2_flags.O_JOINS_IN_UPDATE_CHAIN);
		}
		
		private static function cascadeProperty(root:qb2Object, propertyName:String, value:*):void
		{
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.push(root);
			
			while ( queue.length )
			{
				var subObject:qb2Object = queue.shift();
				
				if ( subObject != root )
				{
					//--- This sub-object loses ownership of this property...it is now considered "inherited" from the root.
					subObject._ownershipFlagsForProperties &= ~_propertyBits[propertyName];
				}
				else
				{
					subObject._ownershipFlagsForProperties |= _propertyBits[propertyName];
				}
				
				subObject._propertyMap[propertyName] = value;
				subObject.propertyChanged(propertyName, value);
				
				if ( subObject is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = subObject as qb2ObjectContainer;
					var numObjects:int = asContainer.numObjects;
					
					for ( var i:int = 0; i < numObjects; i++) 
					{
						queue.push(asContainer._objects[i]);
					}
				}
			}
		}
		
		private static function cascadeFlags(root:qb2Object, affectedFlags:uint):void
		{
			var rootFlags:uint = root._flags;
			
			var queue:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue.push(root);
			
			while ( queue.length )
			{
				var subObject:qb2Object = queue.shift();
				
				if ( subObject != root )
				{
					//--- This sub-object loses ownership of this property...it is now considered "inherited" from the root.
					subObject._ownershipFlagsForBooleans &= ~affectedFlags;
					
					subObject._flags &= ~affectedFlags;
					subObject._flags |= affectedFlags & rootFlags;
				}
				else
				{
					subObject._ownershipFlagsForBooleans |= affectedFlags;
				}
				
				subObject.flagsChanged(affectedFlags);
				
				if ( subObject is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = subObject as qb2ObjectContainer;
					var numObjects:int = asContainer.numObjects;
					
					for ( var i:int = 0; i < numObjects; i++) 
					{
						queue.push(asContainer._objects[i]);
					}
				}
			}
		}
		
		/*qb2_friend function collectAncestorFlagsAndProperties(outputPropertyMap:Object):uint
		{
			var currParent:qb2ObjectContainer = object._parent;
			
			while ( currParent )
			{
				for ( var propertyName:String in _propertyMap )
				{
					if ( currParent.propsSetFlags & PROP_TO_MASK_DICT[propName] )
					{
						if ( !dict )  dict = new Object();
						
						if ( dict[propName] )  continue;
						
						dict[propName] = [currParent[getPrivateVarName(propName)]]; // Add an array with one element for this property name key.
					}
				}
				currParent = currParent._parent;
			}
			
			return dict;
		}
		
		qb2_friend static function cascadeAncestorProperties(object:qb2Tangible, propStacks:Object):void
		{
			if ( !propStacks )  return; // No ancestor objects have any properties explicitly defined.
		
			var redundantProps:Vector.<String> = null;
			var nonRedundantPropertyFound:Boolean = false;
			for ( var propName:String in propStacks )
			{
				var propStack:Array = propStacks[propName];
				
				if ( object.propsSetFlags & PROP_TO_MASK_DICT[propName] )
				{
					if ( !redundantProps )  redundantProps = new Vector.<String>();
					propStack.push(object[getPrivateVarName(propName)]);
				}
				else
				{
					object.setPropertyImplicitly(propName, propStack[propStack.length - 1]);
					nonRedundantPropertyFound = true;
				}
			}
			
			//--- Only continue further down the tree if a property is set by an ancestor that isn't set by 'object'.
			if ( nonRedundantPropertyFound && (object is qb2ObjectContainer) )
			{
				var asContainer:qb2ObjectContainer = object as qb2ObjectContainer;
				for (var i:int = 0; i < asContainer.numObjects; i++) 
				{
					var ithObject:qb2Object = asContainer.getObjectAt(i);
					if ( ithObject is qb2Tangible )
						cascadeAncestorProperties(ithObject as qb2Tangible, propStacks);
					
				}
			}
			
			//--- Have to clear any properties pushed onto the stack, cause we don't want them bleeding into peers' properties.
			if ( redundantProps )
			{
				for ( i = 0; i < redundantProps.length; i++ )
				{
					propStack = propStacks[redundantProps[i]];
					propStack.pop();
				}
			}
		}
		
		qb2_friend static var cancelPropertyInheritance:Boolean = false; // this is invoked by clone functions to cancel the property flow*/
		
		protected virtual function propertyChanged(propertyName:String, value:*):void {}
		
		protected virtual function flagsChanged(affectedFlags:uint):void              {}
		
		qb2_friend static var CONTACT_STARTED_BIT:uint;
		qb2_friend static var CONTACT_ENDED_BIT:uint;
		qb2_friend static var PRE_SOLVE_BIT:uint;
		qb2_friend static var POST_SOLVE_BIT:uint;
		
		qb2_friend static var SUB_CONTACT_STARTED_BIT:uint;
		qb2_friend static var SUB_CONTACT_ENDED_BIT:uint;
		qb2_friend static var SUB_PRE_SOLVE_BIT:uint;
		qb2_friend static var SUB_POST_SOLVE_BIT:uint;
		
		qb2_friend static var ADDED_TO_WORLD_BIT:uint;
		qb2_friend static var REMOVED_FROM_WORLD_BIT:uint;
		qb2_friend static var ADDED_OBJECT_BIT:uint;
		qb2_friend static var REMOVED_OBJECT_BIT:uint;
		qb2_friend static var INDEX_CHANGED_BIT:uint;
		
		qb2_friend static var DESCENDANT_ADDED_OBJECT_BIT:uint;
		qb2_friend static var DESCENDANT_REMOVED_OBJECT_BIT:uint;
		
		qb2_friend static var PRE_UPDATE_BIT:uint;
		qb2_friend static var POST_UPDATE_BIT:uint;
		
		qb2_friend static var MASS_CHANGED_BIT:uint;
		
		qb2_friend static var CONTACT_BITS:uint;
		
		private static function initializeEvents():void
		{
			CONTACT_STARTED_BIT           = registerCachedEvent(new qb2ContactEvent(    qb2ContactEvent.CONTACT_STARTED             ));
			CONTACT_ENDED_BIT             = registerCachedEvent(new qb2ContactEvent(    qb2ContactEvent.CONTACT_ENDED               ));
			PRE_SOLVE_BIT                 = registerCachedEvent(new qb2ContactEvent(    qb2ContactEvent.PRE_SOLVE                   ));
			POST_SOLVE_BIT                = registerCachedEvent(new qb2ContactEvent(    qb2ContactEvent.POST_SOLVE                  ));
			
			SUB_CONTACT_STARTED_BIT       = registerCachedEvent(new qb2SubContactEvent( qb2SubContactEvent.SUB_CONTACT_STARTED      ));
			SUB_CONTACT_ENDED_BIT         = registerCachedEvent(new qb2SubContactEvent( qb2SubContactEvent.SUB_CONTACT_ENDED        ));
			SUB_PRE_SOLVE_BIT             = registerCachedEvent(new qb2SubContactEvent( qb2SubContactEvent.SUB_PRE_SOLVE            ));
			SUB_POST_SOLVE_BIT            = registerCachedEvent(new qb2SubContactEvent( qb2SubContactEvent.SUB_POST_SOLVE           ));
			
			ADDED_TO_WORLD_BIT            = registerCachedEvent(new qb2ContainerEvent(  qb2ContainerEvent.ADDED_TO_WORLD            ));
			REMOVED_FROM_WORLD_BIT        = registerCachedEvent(new qb2ContainerEvent(  qb2ContainerEvent.REMOVED_FROM_WORLD        ));
			ADDED_OBJECT_BIT              = registerCachedEvent(new qb2ContainerEvent(  qb2ContainerEvent.ADDED_OBJECT              ));
			REMOVED_OBJECT_BIT            = registerCachedEvent(new qb2ContainerEvent(  qb2ContainerEvent.REMOVED_OBJECT            ));
			INDEX_CHANGED_BIT             = registerCachedEvent(new qb2ContainerEvent(  qb2ContainerEvent.INDEX_CHANGED             ));
			
			DESCENDANT_ADDED_OBJECT_BIT   = registerCachedEvent(new qb2ContainerEvent(  qb2ContainerEvent.DESCENDANT_ADDED_OBJECT   ));
			DESCENDANT_REMOVED_OBJECT_BIT = registerCachedEvent(new qb2ContainerEvent(  qb2ContainerEvent.DESCENDANT_REMOVED_OBJECT ));
			
			PRE_UPDATE_BIT                = registerCachedEvent(new qb2UpdateEvent(     qb2UpdateEvent.PRE_UPDATE                   ));       
			POST_UPDATE_BIT               = registerCachedEvent(new qb2UpdateEvent(     qb2UpdateEvent.POST_UPDATE                  ));                     
			
			MASS_CHANGED_BIT              = registerCachedEvent(new qb2MassEvent(       qb2MassEvent.MASS_PROPS_CHANGED             ));
			
			CONTACT_BITS =
				CONTACT_STARTED_BIT     | CONTACT_ENDED_BIT     | PRE_SOLVE_BIT     | POST_SOLVE_BIT     |
				SUB_CONTACT_STARTED_BIT | SUB_CONTACT_ENDED_BIT | SUB_PRE_SOLVE_BIT | SUB_POST_SOLVE_BIT ;
			
			eventsInitialized = true;
		}
		
		private static var eventsInitialized:Boolean = false;
		
		public function get parent():qb2ObjectContainer
			{  return _parent;  }
		qb2_friend var _parent:qb2ObjectContainer = null;

		public function get world():qb2World
			{  return _world;  }
		qb2_friend var _world:qb2World = null;
		
		public function removeFromParent():void
			{  this._parent.removeObject(this);  }
			
		public function isDescendantOf(possibleAncestor:qb2ObjectContainer):Boolean
		{
			var object:qb2ObjectContainer = this._parent;
			while ( object )
			{
				if ( object == possibleAncestor )  return true;
				
				object = object._parent;
			}
			return false;
		}
		
		public function isDescendantOfType(possibleAncestorType:Class):Boolean
		{
			var object:qb2ObjectContainer = this._parent;
			while ( object )
			{
				if ( object is possibleAncestorType )  return true;
				
				object = object._parent;
			}
			return false;
		}
		
		public function getAncestorOfType(ancestorType:Class):qb2ObjectContainer
		{
			var object:qb2ObjectContainer = this._parent;
			while ( object )
			{
				if ( object is ancestorType )  return object;
				
				object = object._parent;
			}
			
			return null;
		}
		
		public function getCommonAncestor(otherObject:qb2Object):qb2ObjectContainer
		{
			setAncestorPair(this, otherObject);
			
			var currentLocalObject:qb2Object = setAncestorPair_local;
			
			setAncestorPair_local = null;
			setAncestorPair_other = null;
			
			return currentLocalObject._parent;
		}
		
		//--- These three members act in place of "passing by reference".
		qb2_friend static function setAncestorPair(local:qb2Object, other:qb2Object):void
		{
			if ( local._parent != other._parent )
			{
				var localParentPath:Dictionary = new Dictionary(true);
				localParentPath
				
				while ( local._parent )
				{
					localParentPath[local.parent] = local;
					local = local._parent;
				}
				
				while ( other._parent )
				{
					if ( localParentPath[other._parent] )
					{
						local = localParentPath[other._parent];
						break;
					}
					
					other = other._parent;
				}
			}
			
			setAncestorPair_local = local;
			setAncestorPair_other = other;
		}
		qb2_friend static var setAncestorPair_local:qb2Object = null;
		qb2_friend static var setAncestorPair_other:qb2Object = null;
		
		public function getSeperationFromAncestor(ancestor:qb2ObjectContainer = null):int
		{
			var count:int = 0;
			var currParent:qb2Object = this;
			var foundAncestor:Boolean = false;
			while ( currParent )
			{
				if ( currParent == ancestor )
				{
					foundAncestor = true;
					break;
				}
				
				currParent = currParent._parent;
				count++;
			}
			
			return foundAncestor ? count : count-1;
		}
		
		public function isAbove(otherObject:qb2Object):Boolean
		{
			setAncestorPair(this, otherObject);
			
			var currentLocalObject:qb2Object = setAncestorPair_local;
			var currentOtherObject:qb2Object = setAncestorPair_other;
			
			setAncestorPair_local = null;
			setAncestorPair_other = null;
			
			var common:qb2ObjectContainer = currentLocalObject._parent;
			
			if ( !common )
			{
				throw new Error("Objects don't share a common ancestor!");
			}
			
			var array:Vector.<qb2Object> = common._objects;
			var numObjects:int = array.length;
			for (var i:int = 0; i < numObjects; i++) 
			{
				var item:qb2Object = array[i];
				
				if ( item == currentLocalObject )
				{
					return false;
				}
				else if ( item == currentOtherObject )
				{
					return true;
				}
			}
			
			return false;
		}
		
		public function isBelow(otherObject:qb2Object):Boolean
		{
			return !isAbove(otherObject);
		}
		
		protected function update():void { }
		
		//--- Need this relay function because qb2ObjectContainer can't call protected functions directly.
		qb2_friend function relay_update():void
			{  update();  }
		
		public override function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			var oldFlags:uint = eventFlags;
			
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			
			var eventFlag:uint = getCachedEventBit(type);
			
			var flagAdded:Boolean = oldFlags != eventFlags;
			
			if ( _world )
			{
				if ( eventFlags & PRE_UPDATE_BIT )
				{
					if ( !_world.preEventers[this] )
					{
						_world.preEventers[this] = true;
					}
				}
				if ( eventFlags & POST_UPDATE_BIT )
				{
					if ( !_world.postEventers[this] )
					{
						_world.postEventers[this] = true;
					}
				}
				
				if ( flagAdded && (this is qb2Tangible) )
				{
					if ( eventFlag & CONTACT_BITS )
					{
						var metaBits:uint = this.collectAncestorEventFlags();
						var asTang:qb2Tangible = this as qb2Tangible;
						asTang.updateContactReporting(metaBits);
					}
				}
			}
		}
		
		public override function removeEventListener (type:String, listener:Function, useCapture:Boolean = false) : void
		{
			var oldFlags:uint = eventFlags;
			
			super.removeEventListener(type, listener, useCapture);
			
			var eventFlag:uint = getCachedEventBit(type);
			
			var flagRemoved:Boolean = oldFlags != eventFlags;
			
			if ( _world )
			{
				if ( !(eventFlags & PRE_UPDATE_BIT) )
				{
					if ( _world.preEventers[this] )
						delete _world.preEventers[this];
				}
				if ( !(eventFlags & POST_UPDATE_BIT) )
				{
					if ( _world.postEventers[this] )
						delete _world.postEventers[this];
				}
				
				if ( (this is qb2Tangible) && flagRemoved )
				{					
					if ( eventFlag & CONTACT_BITS )
					{
						var metaBits:uint = this.collectAncestorEventFlags();
						var asTang:qb2Tangible = this as qb2Tangible;
						asTang.updateContactReporting(metaBits);
					}
				}
			}
		}
		
		protected static var reusableV2:V2 = new V2();
		
		private function collectAncestorEventFlags():uint
		{
			var currParent:qb2Object = this;
			var flags:uint = 0;
			while ( currParent )
			{
				flags |= currParent.eventFlags;
				currParent = currParent.parent;
			}
			
			return flags;
		}
		
		qb2_friend function make(theWorld:qb2World):void
		{
			if ( !theWorld )
				throw new Error("World wasn't provided.");
			
			_world = theWorld;
			
			if ( eventFlags & PRE_UPDATE_BIT )
			{
				if( !theWorld.preEventers[this] )  theWorld.preEventers[this] = true;
			}
			if ( eventFlags & POST_UPDATE_BIT )
			{
				if( !theWorld.postEventers[this] )  theWorld.postEventers[this] = true;
			}
			
			if ( eventFlags & ADDED_TO_WORLD_BIT )
			{
				var evt:qb2ContainerEvent = getCachedEvent(qb2ContainerEvent.ADDED_TO_WORLD);
				evt._parentObject = this._parent;
				evt._childObject  = this;
				dispatchEvent(evt);
			}
		}
		
		qb2_friend function destroy():void
		{
			if ( !_world )
				throw new Error("_world isn't defined.");
				
			if ( _world.preEventers[this] )
				delete _world.preEventers[this];
			if ( _world.postEventers[this] )
				delete _world.postEventers[this];
			
			if ( eventFlags & REMOVED_FROM_WORLD_BIT )
			{
				var evt:qb2ContainerEvent = getCachedEvent(qb2ContainerEvent.REMOVED_FROM_WORLD);
				evt._parentObject = this._parent;
				evt._childObject  = this;
				dispatchEvent(evt);
			}
			
			_world = null;
		}
		
		public virtual function draw(graphics:Graphics):void      {}
		
		public virtual function drawDebug(graphics:Graphics):void {}
		
		public function clone():qb2Object
		{
			var cloned:qb2Object = new (this as Object).constructor;
		
			cloned.copyPropertiesAndFlags(this);
			
			return cloned;
		}
		
		qb2_friend function copyPropertiesAndFlags(source:qb2Object):void
		{
			//--- Copy ownership of flags/properties.
			this._ownershipFlagsForBooleans   = source._ownershipFlagsForBooleans;
			this._ownershipFlagsForProperties = source._ownershipFlagsForProperties;
			
			//--- Copy values for flags/properties.
			this._flags = source._flags;
			for ( var key:String in source._propertyMap )
			{
				this._propertyMap[key] = source._propertyMap[key];
			}
		}
		
		/// A convenience function for getting the world's pixelPerMeter property.  If the object isn't in a world, function returns 1.
		public function get worldPixelsPerMeter():Number
			{  return _world ? _world.pixelsPerMeter : 1  }
	}
}