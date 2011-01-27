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

package QuickB2.events 
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import QuickB2.debugging.qb2DebugTraceSettings;
	import QuickB2.qb2_errors;
	import QuickB2.qb2_friend;
	
	use namespace qb2_friend;
	
	/**
	 * Base class for any classes that use QuickB2's optimized event dispatching system.
	 * 
	 * @author Doug Koellmer
	 */
	public class qb2EventDispatcher extends EventDispatcher
	{		
		qb2_friend static const eventMap:Object    = { };
		qb2_friend static const eventBitMap:Object = { };
		
		/** Determines whether any event listeners attached are by default set to weak.
		 * If true, a call like myObject.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, handler) is actually
		 * ammended to myObject.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, handler, false, 0, true) internally.
		 * 
		 * @default true
		 */
		public var useWeakListeners:Boolean = true;
		
		/// This keeps track of the events assigned to an object.  When we want to know whether a certain QuickB2 event is assigned,
		/// a simple bitwise comparison is all that's needed, as opposed to doing hasEventListener(), which has to compare strings and such.
		protected function get eventFlags():uint
			{  return _eventFlags;  }
		qb2_friend var _eventFlags:uint = 0;
		
		protected static function get currEventBit():uint
			{  return _currEventBit;  }
		private static var _currEventBit:uint = 0x00000001;
		
		/// Returns the cached event for a given event type, or null if it doesn't exist.
		protected static function getCachedEvent(eventType:String):*
		{
			var event:* = eventMap[eventType];
			
			if ( !event )
			{
				throw qb2_errors.EVENT_NOT_FOUND;
			}
			
			return event;
		}
		
		/// Gets the event bit for a given event type, or 0 if it doesn't exist.
		protected static function getCachedEventBit(eventType:String):uint
		{
			return eventBitMap[eventType];
		}
		
		/// Registers a cached event and returns the event's bit, which will be compared against an object's
		/// eventFlags in the future to decide if the event needs to be thrown in the first place.
		protected static function registerCachedEvent(event:Event):uint
		{
			if ( !_currEventBit )
			{
				throw qb2_errors.EVENT_CACHE_FULL;
			}
			
			var type:String = event.type;
			eventBitMap[type] = _currEventBit;
			eventMap[type] = event;
			
			var returnBit:uint = _currEventBit;
			_currEventBit = _currEventBit << 1;
			return returnBit;
		}
		
		protected function shouldDispatch(eventType:String):Boolean
		{
			return eventBitMap[eventType] & _eventFlags ? true : false;
		}
		
		public override function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakListeners ? true : useWeakReference);
			
			var eventFlag:uint = getCachedEventBit(type);
			_eventFlags |= eventFlag;
		}
		
		public override function removeEventListener (type:String, listener:Function, useCapture:Boolean = false) : void
		{
			super.removeEventListener(type, listener, useCapture);
			
			var eventFlag:uint = getCachedEventBit(type);
			
			if ( !hasEventListener(type) ) // clear the bit for this event if the object isn't listening for it anymore.
			{
				_eventFlags &= ~eventFlag;
			}
		}
		
		public override function hasEventListener(type:String):Boolean
		{
			if ( _eventFlags & eventBitMap[type] )
			{
				return true;
			}
			
			return super.hasEventListener(type);
		}
		
		public override function toString():String
			{  return qb2DebugTraceSettings.formatToString(this, "qb2EventDispatcher");  }
	}
}