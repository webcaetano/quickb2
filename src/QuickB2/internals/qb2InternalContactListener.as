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

package QuickB2.internals
{
	import As3Math.geo2d.*;
	import Box2DAS.Collision.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Contacts.*;
	import flash.utils.*;
	import QuickB2.events.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;

	import QuickB2.*;
	use namespace qb2_friend;

	/**
	 * ...
	 * @author Doug Koellmer
	 * @private
	 */
	public class qb2InternalContactListener extends b2ContactListener
	{
		private var CONTACT_STARTED_BIT:uint, CONTACT_ENDED_BIT:uint, PRE_SOLVE_BIT:uint, POST_SOLVE_BIT:uint;
		private var SUB_CONTACT_STARTED_BIT:uint, SUB_CONTACT_ENDED_BIT:uint, SUB_PRE_SOLVE_BIT:uint, SUB_POST_SOLVE_BIT:uint;
		
		private static const eventFlagToCachedEventMap:Dictionary = new Dictionary();
		
		public function qb2InternalContactListener()
		{			
			//--- This is done to cut down on costly class look-ups whenever a collision is detected.
			//--- Local instance variables are much faster to access than static variables of other classes.
			CONTACT_STARTED_BIT     = qb2Object.CONTACT_STARTED_BIT;
			CONTACT_ENDED_BIT       = qb2Object.CONTACT_ENDED_BIT;
			PRE_SOLVE_BIT           = qb2Object.PRE_SOLVE_BIT;
			POST_SOLVE_BIT          = qb2Object.POST_SOLVE_BIT;
			SUB_CONTACT_STARTED_BIT = qb2Object.SUB_CONTACT_STARTED_BIT;
			SUB_CONTACT_ENDED_BIT   = qb2Object.SUB_CONTACT_ENDED_BIT;
			SUB_PRE_SOLVE_BIT       = qb2Object.SUB_PRE_SOLVE_BIT;
			SUB_POST_SOLVE_BIT      = qb2Object.SUB_POST_SOLVE_BIT;
			
			//--- Build up a flag-to-event map, again for slightly more efficiency over class look-ups, and no if-elsing.
			eventFlagToCachedEventMap[CONTACT_STARTED_BIT]     = qb2EventDispatcher.eventMap["contactStarted"];
			eventFlagToCachedEventMap[CONTACT_ENDED_BIT]       = qb2EventDispatcher.eventMap["contactEnded"];
			eventFlagToCachedEventMap[PRE_SOLVE_BIT]           = qb2EventDispatcher.eventMap["preSolve"];
			eventFlagToCachedEventMap[POST_SOLVE_BIT]          = qb2EventDispatcher.eventMap["postSolve"];
			eventFlagToCachedEventMap[SUB_CONTACT_STARTED_BIT] = qb2EventDispatcher.eventMap["subContactStarted"];
			eventFlagToCachedEventMap[SUB_CONTACT_ENDED_BIT]   = qb2EventDispatcher.eventMap["subContactEnded"];
			eventFlagToCachedEventMap[SUB_PRE_SOLVE_BIT]       = qb2EventDispatcher.eventMap["subPreSolve"];
			eventFlagToCachedEventMap[SUB_POST_SOLVE_BIT]      = qb2EventDispatcher.eventMap["subPostSolve"];
		}

		private function getDistToWorld(obj:qb2Tangible):int
		{
			var count:int = 0;
			var currParent:qb2Tangible = obj;
			while ( currParent != obj._world )
			{
				count++;
				currParent = currParent._parent;
			}
			
			return count;
		}
		
		private function dispatchSubContactEvent(shape1:qb2Shape, shape2:qb2Shape, contact:b2Contact, eventFlag:uint):void
		{		
			var currParent:qb2ObjectContainer = shape1.parent;
			while ( currParent )
			{
				if ( currParent._eventFlags & eventFlag )
				{
					if ( shape2.isDescendantOf(currParent)  )
					{
						var subEvent:qb2SubContactEvent = eventFlagToCachedEventMap[eventFlag] as qb2SubContactEvent;
						subEvent._shape1 = shape1;
						subEvent._shape2 = shape2;
						subEvent._ancestorGroup = currParent as qb2Group;
						subEvent._contactB2 = contact;
						subEvent._world = shape1.world;
						
						currParent.dispatchEvent(subEvent);
					}				
				}
				
				currParent = currParent.parent;
			}
		}
		
		private function dispatchContactEvent(shape1:qb2Shape, shape2:qb2Shape, contact:b2Contact, eventFlag:uint):void
		{
			var currParent:qb2Tangible = shape1;
			
			while ( currParent && !(currParent is qb2World) )
			{
				if ( currParent._eventFlags & eventFlag )
				{
					if ( currParent is qb2Group )
					{
						var asGroup:qb2Group = currParent as qb2Group;
						if ( shape1.isDescendantOf(asGroup) && shape2.isDescendantOf(asGroup ) )
						{
							currParent = currParent.parent;
							continue; // contact events aren't dispatched when the dispatcher is a group containing the two shapes that contacted.
						}
					}
					
					var event:qb2ContactEvent = eventFlagToCachedEventMap[eventFlag] as qb2ContactEvent;
					event._localShape = shape1;
					event._otherShape = shape2;
					event._localObject = currParent;
					qb2Object.setAncestorPair(currParent, shape2);
					event._otherObject = qb2Object.setAncestorPair_other as qb2Tangible; // TADA!!!
					qb2Object.setAncestorPair_local = null;
					qb2Object.setAncestorPair_other = null;
					event._contactB2 = contact;
					event._world = shape1.world;
					
					currParent.dispatchEvent(event);
				}
				
				currParent = currParent.parent;
			}
		}
		
		public override function BeginContact(contact:b2Contact):void
		{//trace("ADDED");
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_CONTACT_STARTED_BIT);
			dispatchContactEvent(shape1, shape2, contact, CONTACT_STARTED_BIT);
			dispatchContactEvent(shape2, shape1, contact, CONTACT_STARTED_BIT);
		}
		
		public override function EndContact(contact:b2Contact):void
		{//trace("REMOVED");
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_CONTACT_ENDED_BIT);
			dispatchContactEvent(shape1, shape2, contact, CONTACT_ENDED_BIT);
			dispatchContactEvent(shape2, shape1, contact, CONTACT_ENDED_BIT);
		}
		
		public override function PreSolve(contact:b2Contact, oldManifold:b2Manifold):void
		{//trace("PRESOLVE");
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_PRE_SOLVE_BIT);
			dispatchContactEvent(shape1, shape2, contact, PRE_SOLVE_BIT);
			dispatchContactEvent(shape2, shape1, contact, PRE_SOLVE_BIT);
		}
		
		public override function PostSolve(contact:b2Contact, impulse:b2ContactImpulse):void
		{//trace("POSTSOLVE");
			var shape1:qb2Shape = contact.GetFixtureA().GetUserData() as qb2Shape;
			var shape2:qb2Shape = contact.GetFixtureB().GetUserData() as qb2Shape;
			
			if ( shape1.flaggedForDestroy || shape2.flaggedForDestroy )  return;
			
			dispatchSubContactEvent(shape1, shape2, contact, SUB_POST_SOLVE_BIT);
			dispatchContactEvent(shape1, shape2, contact, POST_SOLVE_BIT);
			dispatchContactEvent(shape2, shape1, contact, POST_SOLVE_BIT);
		}
	}
}