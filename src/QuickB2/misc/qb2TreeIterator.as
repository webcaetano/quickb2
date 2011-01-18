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
		public function qb2TreeIterator(initRoot:qb2ObjectContainer) 
		{
			if ( !_singleton )
				_singleton = this;
				
			root = initRoot;
		}
		
		public static function get singleton():qb2TreeIterator
			{  return _singleton ? _singleton : _singleton = new qb2TreeIterator();  }
		private static var _singleton:qb2TreeIterator = null;
		
		public function get root():qb2ObjectContainer
			{  return _root;  }
		public function set root(aContainer:qb2ObjectContainer):void
		{
			reset();
			_root = aContainer;
			
			if( _root )
				queue.unshift(_root);
		}
		private var _root:qb2ObjectContainer;
		
		public function hasNext():Boolean
			{  return _queue.length > 0;  }
		
		public function next(... types):qb2Object
		{
			if ( !_root )  return null;
			
			if ( !_queue.length )  return null;
			
			_currObject = step();
			
			if ( !types.length )
			{
				return _currObject;
			}
			else
			{
				for (var j:int = 0; j < types.length; j++) 
				{
					if ( _currObject is types[j] )
					{
						return _currObject;
					}
				}
				
				while ( _queue.length )
				{
					_currObject = step();
					
					for ( j = 0; j < types.length; j++) 
					{
						if ( _currObject is types[j] )
						{
							return _currObject;
						}
					}
				}
			}
			
			return null;
		}
		
		private function step():qb2Object
		{
			var object:qb2Object = _queue.shift();
			
			if ( object is qb2ObjectContainer )
			{
				var asContainer:qb2ObjectContainer = object as qb2ObjectContainer;
				for (var i:int = 0; i < asContainer.numObjects; i++) 
				{
					_queue.unshift(asContainer.getObjectAt(i));
				}
			}
			
			return object;
		}
		
		public function reset():void
		{
			_root = _currObject = null;
			_queue.length = 0;
		}
		
		public function get currObject():qb2Object
			{  return _currObject;  }
		private var _currObject:qb2Object;
		
		private const _queue:Vector.<qb2Object> = new Vector.<qb2Object>();
	}
}