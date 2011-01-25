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
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
	
	/**
	 * Provides a convenient way to traverse a qb2ObjectContainer hierarchy in level order.
	 * Singleton is provided so you really only have to instatiate one of these and reuse it.
	 * 
	 * @author Doug Koellmer
	 */
	public class qb2TreeIterator
	{
		public static const LEFT_TO_RIGHT:uint = 1;
		public static const RIGHT_TO_LEFT:uint = 2;
		
		public var direction:uint = LEFT_TO_RIGHT;
		
		public function qb2TreeIterator(initRoot:qb2ObjectContainer = null, initDirection:uint = LEFT_TO_RIGHT) 
		{
			direction = initDirection;
			root = initRoot;
		}
		
		public static function getSingleton(initRoot:qb2ObjectContainer = null):qb2TreeIterator
		{
			if ( _singleton )
			{
				_singleton.root = initRoot;
			}
			else
			{
				_singleton = new qb2TreeIterator(initRoot);
			}
			
			return _singleton;
		}
		private static var _singleton:qb2TreeIterator;
		
		public function get root():qb2ObjectContainer
			{  return _root;  }
		public function set root(aContainer:qb2ObjectContainer):void
		{
			clear();
			_root = aContainer;
			
			if ( _root )
			{
				_queue.push(_root);
			}
		}
		private var _root:qb2ObjectContainer;
		
		public function hasNext():Boolean
		{
			return _queue.length > 0;
		}
		
		public function get currentObject():qb2Object
			{  return _queue.length ? _queue[0] : null;  }
		
		public function next(proceedDownBranch:Boolean = true):qb2Object
		{
			if ( !_root )  return null;
			
			if ( !_queue.length )  return null;
			
			_currObject = _queue.shift();
			
			if ( proceedDownBranch )
			{
				if ( _currObject is qb2ObjectContainer )
				{
					var asContainer:qb2ObjectContainer = _currObject as qb2ObjectContainer;
					var numObjects:int = asContainer.numObjects;
					
					if ( direction == RIGHT_TO_LEFT )
					{
						for (var i:int = numObjects-1; i >= 0; i--) 
						{
							_queue.push(asContainer.getObjectAt(i));
						}
					}
					else
					{
						for ( i = 0; i < numObjects; i++)
						{
							_queue.push(asContainer.getObjectAt(i));
						}
					}
				}
			}
			
			return _currObject;
		}
		
		public function reset():void
		{
			_currObject = null;
			_queue.length = 0;
			
			if ( _root )
			{
				_queue.unshift(_root);
			}
		}
		
		public function clear():void
		{
			_root = null;
			_currObject = null;
			_queue.length = 0;
		}
		
		public function get currObject():qb2Object
			{  return _currObject;  }
		private var _currObject:qb2Object;
		
		private const _queue:Vector.<qb2Object> = new Vector.<qb2Object>();
	}
}