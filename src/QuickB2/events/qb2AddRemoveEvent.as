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
	import flash.events.*;
	import QuickB2.*;
	import QuickB2.debugging.qb2DebugTraceSettings;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2AddRemoveEvent extends qb2Event
	{
		public static const ADDED_OBJECT:String              = "addedObject";
		public static const REMOVED_OBJECT:String            = "removedObject";
		public static const DESCENDANT_ADDED_OBJECT:String   = "descendantAddedObject";
		public static const DESCENDANT_REMOVED_OBJECT:String = "descendantRemovedObject";
		public static const ADDED_TO_WORLD:String            = "addedToWorld";
		public static const REMOVED_FROM_WORLD:String        = "removedFromWorld";
		
		qb2_friend var _childObject:qb2Object;
		qb2_friend var _parentObject:qb2ObjectContainer;
		
		public function qb2AddRemoveEvent(type:String) 
		{
			super(type);
		}
		
		public override function clone():Event
		{
			var evt:qb2AddRemoveEvent = new qb2AddRemoveEvent(type);
			evt._childObject  = _childObject;
			evt._parentObject = _parentObject;
			return evt;
		}
		
		public function get childObject():qb2Object
		{
			return _childObject;
		}
		
		public function get parentObject():qb2ObjectContainer
		{
			return _parentObject;
		}
		
		public override function toString():String 
			{  return qb2DebugTraceSettings.formatToString(this, "qb2AddRemoveEvent");  }
	}
}