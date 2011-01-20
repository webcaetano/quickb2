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

package QuickB2.stock 
{
	import Box2DAS.Common.b2Def;
	import flash.utils.Dictionary;
	import QuickB2.events.qb2ContactEvent;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2Shape;
	import QuickB2.objects.tangibles.qb2Tangible;
	import QuickB2.qb2_friend;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Terrain extends qb2Body
	{
		public function qb2Terrain(ubiquitous:Boolean = false) 
		{
			_ubiquitous = ubiquitous;
			
			isGhost = true;
			
			if ( !_ubiquitous )
			{
				addContactListeners();
			}
			
			addEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     addedOrRemoved, false, 0, true);
			addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved, false, 0, true);
		}
		
		private function addContactListeners():void
		{
			addEventListener(qb2ContactEvent.CONTACT_STARTED, contact, false, 0, true);
			addEventListener(qb2ContactEvent.CONTACT_ENDED,   contact, false, 0, true);
		}
		
		private function removeContactListeners():void
		{
			removeEventListener(qb2ContactEvent.CONTACT_STARTED, contact);
			removeEventListener(qb2ContactEvent.CONTACT_ENDED,   contact);
		}
		
		public function get ubiquitous():Boolean
			{  return _ubiquitous;  }
		private var _ubiquitous:Boolean = false;
		
		//--- Terrain is organized z-wise with other terrains globally whenever one is added to the world.
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				world.registerGlobalTerrain(this);
			}
			else
			{
				world.unregisterGlobalTerrain(this);
			}
		}
		
		public function get frictionZMultiplier():Number
			{  return _frictionZMultiplier;  }
		public function set frictionZMultiplier(value:Number):void 
		{
			_frictionZMultiplier = value;
			
			for (var key:* in bodyDict )
			{
				(key as qb2Tangible).rigid_updateFrictionJoints();
			}
		}
		private var _frictionZMultiplier:Number = 1;
		
		private var bodyDict:Dictionary = new Dictionary(true);
		private static const NUM_SHAPES:String = "NUM_SHAPES";
		
		private function contact(evt:qb2ContactEvent):void
		{
			var otherShape:qb2Shape = evt.otherShape;
			var realBody:qb2Tangible = otherShape;
			
			while ( realBody )
			{
				if ( realBody._bodyB2 )
				{
					break;
				}
				
				realBody = realBody.parent;
			}
			
			if ( !realBody )  return;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				if ( !bodyDict[realBody] )
				{
					bodyDict[realBody] = new Dictionary(true);
					bodyDict[realBody][NUM_SHAPES] = 0;
					
					realBody.registerContactTerrain(this);
				}
				
				var shapeDict:Dictionary = bodyDict[realBody];
				
				if ( !shapeDict[otherShape] )
				{
					shapeDict[NUM_SHAPES]++;
					shapeDict[otherShape] = 0;
				}
				
				shapeDict[otherShape]++;
			}
			else
			{
				shapeDict = bodyDict[realBody];
				
				if ( shapeDict )
				{
					if ( shapeDict[otherShape] )
					{
						shapeDict[otherShape]--;
						
						if ( shapeDict[otherShape] == 0 )
						{
							delete shapeDict[otherShape];
							shapeDict[NUM_SHAPES]--;
							
							if ( shapeDict[NUM_SHAPES] == 0 )
							{
								delete bodyDict[realBody];
								realBody.unregisterContactTerrain(this);
							}
						}
					}
					else
					{
						throw new Error("huh?");
					}
				}
				else
				{
					throw new Error("huh?");
				}
			}
		}
		
		public override function clone():qb2Object
		{
			var cloned:qb2Terrain = super.clone() as qb2Terrain;
			
			cloned.frictionZMultiplier = this.frictionZMultiplier;
			cloned._ubiquitous = this._ubiquitous;
			
			if ( cloned._ubiquitous )
			{
				cloned.removeContactListeners();
			}
			
			return cloned;
		}
	}
}