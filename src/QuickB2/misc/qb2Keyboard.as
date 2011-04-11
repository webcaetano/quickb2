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
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	import QuickB2.events.*;
	
	[Event(name="keyDown", type="flash.events.KeyboardEvent")]
	[Event(name="keyUp",   type="flash.events.KeyboardEvent")]
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Keyboard extends EventDispatcher
	{
		private const _keyMap:Dictionary     = new Dictionary();
		private const _history:Vector.<uint> = new Vector.<uint>();
		
		public var suppressEvents:Boolean = false;
		
		public var anyKeyDown:Function;
		public var anyKeyUp:Function;
		
		public function qb2Keyboard(theStage:Stage):void
		{
			_stage = theStage;
			
			if ( _stage )
			{
				_stage.addEventListener(KeyboardEvent.KEY_DOWN, keyEvent, false, 0, true );
				_stage.addEventListener(KeyboardEvent.KEY_UP,   keyEvent, false, 0, true );	
			}
		}
		
		public static function makeSingleton(theStage:Stage):qb2Keyboard
		{
			if ( !_singleton )
				_singleton = new qb2Keyboard(theStage);
				
			return _singleton;
		}
		
		public function releaseListeners():void
		{
			if ( _stage )
			{
				_stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyEvent, false );
				_stage.removeEventListener(KeyboardEvent.KEY_UP,   keyEvent, false );
			}
			
			_history.length = 0;
			
			for ( var key:* in _keyMap )
			{
				delete _keyMap[key];
			}
		}
		
		private function keyEvent(evt:KeyboardEvent):void
		{
			var keyCode:uint = evt.keyCode;
			var down:Boolean = evt.type == KeyboardEvent.KEY_DOWN;
			
			if ( _keyMap[keyCode] && !down )
			{
				_lastKeyUp = keyCode;
				delete _keyMap[keyCode];
				_history.splice(_history.indexOf(keyCode), 1);
				if ( !suppressEvents )
					dispatchEvent(evt);
				
				if ( anyKeyUp != null )  anyKeyUp.call();
			}
			else if( !_keyMap[keyCode] && down )
			{
				_lastKeyDown = keyCode;
				_keyMap[keyCode] = true;
				_history.push(keyCode);
				if ( !suppressEvents )
					dispatchEvent(evt);
				
				if ( anyKeyDown != null )  anyKeyDown.call();
			}
		}
		
		public function get numKeysDown():uint
			{  return _history.length;  }
			
		public function getKeyAt(index:uint):uint
			{  return _history[index];  }
			
		public function lastKeyPressed(... amongTheseKeys):uint
		{
			var highestKey:uint = 0;
			var queries:Vector.<uint> = parseToOneVector(amongTheseKeys);
			for (var i:int = 0; i < _history.length; i++) 
			{
				var historyKey:uint = _history[i];
				
				for (var j:int = 0; j < queries.length; j++) 
				{
					var queryKey:uint = queries[j];
					
					if ( historyKey == queryKey )
					{
						highestKey = queryKey;
						break;
					}
				}
			}
			
			return highestKey;
		}
		
		public function get lastKeyUp():uint
			{  return _lastKeyUp;  }
		private var _lastKeyUp:uint;
		
		public function get lastKeyDown():uint
			{  return _lastKeyDown;  }
		private var _lastKeyDown:uint;
		
		public function isDown(... oneOrMoreKeys):Boolean
		{
			var queries:Vector.<uint> = parseToOneVector(oneOrMoreKeys);
			for (var i:int = 0; i < queries.length; i++) 
			{
				var keyCode:uint = queries[i];
				
				if ( _keyMap[keyCode] )
				{
					return true;
				}
			}
			
			return false;
		}
		
		private function parseToOneVector(array:Array):Vector.<uint>
		{
			var vector:Vector.<uint> = new Vector.<uint>();
			for ( var i:int = 0; i < array.length; i++ )
			{
				var item:Object = array[i];
				
				if ( item is uint )
				{
					vector.push(item as uint);
				}
				else if ( item is Array )
				{
					var subarray:Array = item as Array;
					for (var j:int = 0; j < subarray.length; j++) 
					{
						var subitem:Object = subarray[j];
						if ( subitem is uint )
						{
							vector.push(subitem);
						}
					}
				}
				else if ( item is Vector.<uint> )
				{
					var subvector:Vector.<uint> = item as Vector.<uint>;
					for ( j = 0; j < subvector.length; j++) 
					{
						subitem = subvector[j];
						if ( subitem is uint )
						{
							vector.push(subitem);
						}
					}
				}
			}
			
			return vector;
		}
		
		public function get stage():Stage
			{  return _stage;  }
		private var _stage:Stage;
		
		public static function get singleton():qb2Keyboard
			{  return _singleton;  }
		private static var _singleton:qb2Keyboard;
	}
}