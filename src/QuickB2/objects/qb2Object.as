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
	import QuickB2.objects.joints.*;
	import QuickB2.objects.tangibles.*;
	use namespace qb2_friend;
	
	[Event(name="preUpdate",  type="QuickB2.events.qb2UpdateEvent")]
	[Event(name="postUpdate", type="QuickB2.events.qb2UpdateEvent")]
	
	[Event(name="addedToWorld",     type="QuickB2.events.qb2ContainerEvent")]
	[Event(name="removedFromWorld", type="QuickB2.events.qb2ContainerEvent")]
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Object extends qb2EventDispatcher
	{
		public var identifier:String = "";
		
		/// Whether or not this object will draw itself if the world has debugDrawContext defined.
		public var drawsDebug:Boolean = true;
		
		public function qb2Object()
		{
			if ( (this as Object).constructor == qb2Object )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
			
			if ( !eventsInitialized )
			{
				initializeEvents();
			}
		}
		
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
			var currLocal:qb2Object = local;
			
			if ( local._parent != other._parent )
			{
				var localParentPath:Dictionary = new Dictionary(true);
				
				while ( local._parent )
				{
					localParentPath[local.parent] = true;
					currLocal = local;
					local = local._parent;
				}
				
				while ( other._parent )
				{
					if ( localParentPath[other._parent] )
					{
						break;
					}
					
					other = other._parent;
				}
			}
			
			setAncestorPair_local = currLocal;
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
		
		//--- Need this relay function because qb2ObjectContainer can't call protected functions like this directly.
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
						var metaBits:uint = this.collectAncestorBits();
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
						var metaBits:uint = this.collectAncestorBits();
						var asTang:qb2Tangible = this as qb2Tangible;
						asTang.updateContactReporting(metaBits);
					}
				}
			}
		}
		
		protected static var reusableV2:V2 = new V2();
		
		private function collectAncestorBits():uint
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
		
		public virtual function draw(graphics:Graphics):void {}
		
		public virtual function drawDebug(graphics:Graphics):void { }
		
		public virtual function clone():qb2Object {  return null;  }
		
		/// A convenience function for getting the world's pixelPerMeter property.  If the object isn't in a world, function returns 1.
		public function get worldPixelsPerMeter():Number
			{  return _world ? _world.pixelsPerMeter : 1  }
	}
}