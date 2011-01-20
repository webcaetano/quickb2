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

package TopDown.ai.brains
{
	import flash.display.Graphics;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.qb2_errors;
	import TopDown.*;
	import TopDown.objects.*;
	
	use namespace td_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdBrain
	{	
		public function tdBrain()
		{
			if ( Object(this).constructor == tdBrain )
					throw qb2_errors.ABSTRACT_CLASS_ERROR;
		}
		
		td_friend function relay_update():void
			{  update();  }
		
		td_friend function setHost(aSmartBody:tdSmartBody):void
		{
			if ( _host )
			{
				_host.brainPort.clear();
				removedFromHost();
				
				_host.removeEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     hostAddedOrRemoved);
				_host.removeEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, hostAddedOrRemoved);
				
				if ( _host.world )
				{
					removedFromWorld();
				}
			}
			
			_host = aSmartBody;

			if ( _host )
			{
				addedToHost();
				
				_host.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     hostAddedOrRemoved);
				_host.addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, hostAddedOrRemoved);
				
				if ( _host.world )
				{
					addedToWorld();
				}
			}
		}
		
		private function hostAddedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				addedToWorld();
			}
			else
			{
				removedFromWorld();
			}
		}
		
		public function get host():tdSmartBody
			{  return _host;  }
		private var _host:tdSmartBody;
			
		protected virtual function addedToHost():void { }
		protected virtual function removedFromHost():void { }
		protected virtual function addedToWorld():void {}
		protected virtual function removedFromWorld():void {}
		protected virtual function update():void  { }
		
		public virtual function drawDebug(graphics:Graphics):void { };
	}
}