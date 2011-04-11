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

package QuickB2.misc
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.events.*;
	import QuickB2.events.*;
	import revent.rEventDispatcher;
	import revent.rIEventDispatcher;
	
	[Event(name="mouseDown", type="flash.events.MouseEvent")]
	[Event(name="mouseUp",   type="flash.events.MouseEvent")]
	[Event(name="mouseOut",  type="flash.events.MouseEvent")]
	[Event(name="mouseOver", type="flash.events.MouseEvent")]
	[Event(name="click",     type="flash.events.MouseEvent")]
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Mouse extends EventDispatcher
	{
		public var suppressEvents:Boolean = false;
		
		public var mouseWentDown:Function;
		public var mouseWentUp:Function;
		
		public function qb2Mouse(initInteractiveSource:InteractiveObject) 
		{
			interactiveSource = initInteractiveSource;
		}
		
		private function mouseEvent(evt:MouseEvent):void
		{
			if ( evt.type == MouseEvent.MOUSE_DOWN )
			{
				if ( !suppressEvents )
				{
					dispatchEvent(evt);
					_isDown = true;
					
					if ( mouseWentDown != null )  mouseWentDown.call();
				}
			}
			else if ( evt.type == MouseEvent.MOUSE_UP )
			{
				if ( !suppressEvents )
				{
					dispatchEvent(evt);
					_isDown = false;
					
					if ( mouseWentUp != null )  mouseWentUp.call();
				}
			}
			else
			{
				if ( !suppressEvents )
				{
					dispatchEvent(evt);
				}
			}
			
			_lastEventType   = evt.type;
			_lastEventTarget = evt.target;
		}
		
		public static function makeSingleton(interactiveSource:InteractiveObject):void
		{
			if ( !_singleton )
				_singleton = new qb2Mouse(interactiveSource);
		}
		
		public function get lastEventType():String
			{  return _lastEventType;  }
		private var _lastEventType:String = "";
		
		public function get lastEventTarget():Object
			{  return _lastEventTarget;  }
		private var _lastEventTarget:Object = null;
		
		public function get isDown():Boolean
			{  return _isDown;  }
		private var _isDown:Boolean = false;
		
		public function get position():amPoint2d
			{  return new amPoint2d(_interactiveSource.mouseX, _interactiveSource.mouseY);  }
			
		public function get mouseX():Number
			{  return _interactiveSource.mouseX;  }
			
		public function get mouseY():Number
			{  return _interactiveSource.mouseY;  }
		
		public function set interactiveSource(source:InteractiveObject):void
		{
			if ( _interactiveSource )
			{
				_interactiveSource.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
				_interactiveSource.removeEventListener(MouseEvent.MOUSE_UP,   mouseEvent);
				_interactiveSource.removeEventListener(MouseEvent.MOUSE_OUT,  mouseEvent);
				_interactiveSource.removeEventListener(MouseEvent.MOUSE_OVER, mouseEvent);
				_interactiveSource.removeEventListener(MouseEvent.CLICK,      mouseEvent);
			}
			
			_interactiveSource = source;
			
			if ( _interactiveSource )
			{
				_interactiveSource.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent, false, 0, true );
				_interactiveSource.addEventListener(MouseEvent.MOUSE_UP,   mouseEvent, false, 0, true );
				_interactiveSource.addEventListener(MouseEvent.MOUSE_OUT,  mouseEvent, false, 0, true );
				_interactiveSource.addEventListener(MouseEvent.MOUSE_OVER, mouseEvent, false, 0, true );
				_interactiveSource.addEventListener(MouseEvent.CLICK,      mouseEvent, false, 0, true );
			}
			
			_isDown = false;
		}
		public function get interactiveSource():InteractiveObject
			{  return _interactiveSource;  }
		private var _interactiveSource:InteractiveObject;
		
		public static function get singleton():qb2Mouse
			{  return _singleton;  }
		private static var _singleton:qb2Mouse;
	}
}