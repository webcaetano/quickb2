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

package QuickB2.effects 
{
	import adobe.utils.CustomActions;
	import flash.display.Graphics;
	import flash.utils.Dictionary;
	import QuickB2.debugging.*;
	import QuickB2.events.qb2ContactEvent;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.misc.*;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.*;
	import QuickB2.qb2_errors;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2EffectField extends qb2Body
	{
		private var instanceFilter:Dictionary = null;
		private var typeFilter:Dictionary = null;
		
		public function qb2EffectField(ubiquitous:Boolean = false)
		{
			_ubiquitous = ubiquitous;
			
			isGhost = true;
			
			if ( !_ubiquitous )
			{
				addContactListeners();
			}
			else
			{
				addContainerEventListeners();
			}
			
			if ( (this as Object).constructor == qb2EffectField )  throw qb2_errors.ABSTRACT_CLASS_ERROR;
		}
		
		private static const weakKeys:Boolean = true;
		
		public function disableForType(type:Class):void
		{
			typeFilter = typeFilter ? typeFilter : new Dictionary(weakKeys);
			typeFilter[type] = false;
		}
		
		public function enableForType(type:Class):void
		{
			if ( !typeFilter )  return;
			
			if ( typeFilter[type] )
			{
				delete typeFilter[type];
			}
		}
		
		public function disableForInstance(object:qb2Tangible):void
		{
			instanceFilter = instanceFilter ? instanceFilter : new Dictionary(weakKeys);
			instanceFilter[object] = false;
		}
		
		public function enableForInstance(object:qb2Tangible):void
		{
			instanceFilter = instanceFilter ? instanceFilter : new Dictionary(weakKeys);
			instanceFilter[object] = true;
		}
		
		
		protected final function shouldApply(toObject:qb2Tangible):Boolean
		{
			if ( instanceFilter && instanceFilter[toObject] )
			{
				return instanceFilter[toObject];
			}
			
			if ( typeFilter )
			{
				for ( var key:* in typeFilter )
				{
					if ( toObject is (key as Class) )
					{
						return typeFilter[key] as Boolean;
					}
				}
			}
			
			return true;
		}
		
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				parent.effectFields = parent.effectFields ? parent.effectFields : new Vector.<qb2EffectField>();
				parent.effectFields.push(this);
			}
			else
			{
				if ( parent.effectFields )
				{
					var index:int = parent.effectFields.indexOf(this);
					
					if ( index >= 0 )
					{
						parent.effectFields.splice(index, 1);
					}
				}
			}
		}
		
		public function get ubiquitous():Boolean
			{  return _ubiquitous;  }
		private var _ubiquitous:Boolean = false;
		
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
		
		private function addContainerEventListeners():void
		{
			addEventListener(qb2ContainerEvent.ADDED_TO_WORLD,     addedOrRemoved, false, 0, true);
			addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved, false, 0, true);
		}
		
		private var shapeContactDict:Dictionary = new Dictionary(weakKeys);
		
		private function contact(evt:qb2ContactEvent):void
		{
			var otherShape:qb2Shape = evt.otherShape;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				if ( !shapeContactDict[otherShape] )
				{
					shapeContactDict[otherShape] = 0 as int;
					
					//--- Add the effect to the shape's effects list.
					otherShape.effectFields = otherShape.effectFields ? otherShape.effectFields : new Vector.<qb2EffectField>();
					otherShape.effectFields.push(this);
				}
				
				shapeContactDict[otherShape]++;
			}
			else
			{
				shapeContactDict[otherShape]--;
				
				if ( shapeContactDict[otherShape] == 0 ) 
				{
					delete shapeContactDict[otherShape];
					
					if ( otherShape.effectFields )
					{
						var index:int = otherShape.effectFields.indexOf(this);
						if ( index >= 0 )
						{
							otherShape.effectFields.splice(index, 1);
						}
					}
				}
			}
		}
		
		protected static var utilTraverser:qb2TreeTraverser = new qb2TreeTraverser();
		
		public virtual function apply(toObject:qb2Tangible):void
		{
			
		}
		
		public override function drawDebug(graphics:Graphics):void
		{
			debugFillColorStack.unshift(qb2_debugDrawSettings.effectFieldFillColor);
				super.drawDebug(graphics);
			debugFillColorStack.shift();
		}
		
		public override function clone():qb2Object
		{
			var cloned:qb2EffectField = super.clone() as qb2EffectField;
			
			cloned._ubiquitous = this._ubiquitous;
			
			if ( cloned._ubiquitous )
			{
				cloned.removeContactListeners();
				cloned.addContainerEventListeners();
			}
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2DebugTraceSettings.formatToString(this, "qb2EffectField");  }
	}
}