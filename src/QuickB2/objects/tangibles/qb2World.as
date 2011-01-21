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

package QuickB2.objects.tangibles
{	
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.*;
	import Box2DAS.Collision.Shapes.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import Box2DAS.Dynamics.Joints.*;
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.debugging.*;
	import QuickB2.events.*;
	import QuickB2.internals.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.stock.qb2Terrain;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2World extends qb2Group
	{
		qb2_friend const preEventers:Dictionary = new Dictionary(true);
		qb2_friend const postEventers:Dictionary = new Dictionary(true);
		
		qb2_friend var _worldB2:b2World;
		
		/** The default time step (in seconds) to take on each update.  You generally want this to coincide with your display rate.
		 * This value is ignored if realTimeUpdate=true
		 * @default 1.0/30.0
		 * @see #realTimeUpdate
		 */
		public var defaultTimeStep:Number   = 1.0 / 30.0;
		
		/** If true, things will update based on the actual elapsed time since the last update.
		 * If false, the simulation will update on the fixed time step specified by defaultTimeStep.
		 * @default true
		 * @see #defaultTimeStep
		 */
		public var realtimeUpdate:Boolean = false;
		
		/** Number of iterations to use for each update. A higher number will produce a slower but more accurate simulation.  Lower, vice
		 * versa. The default of 10 is suitable for most real time physics simulations.  Rarely will you have to change this.
		 * @default 3
		 */
		public var defaultPositionIterations:uint = 3;
		public var defaultVelocityIterations:uint = 8;
		
		/** If realtimeUpdate is true, this is the maximum step that will be taken per frame.  Large timesteps cause instabilities.
		 * @default = 1.0/20.0
		 * @see #realtimeUpdate
		 */
		public var maximumRealtimeStep:Number = 1.0/20.0;
		
		private var lastTime:Number = 0;
	
		//---- Used to register an event loop.
		private var eventer:Sprite = new Sprite();
		
		public function get background():qb2Body
			{  return _background;  }
		qb2_friend var _background:qb2Body = new qb2Body();
		
		qb2_friend var processingBox2DStuff:Boolean = false;
		
		private const delayedCalls:Vector.<qb2InternalDelayedCall> = new Vector.<qb2InternalDelayedCall>();
		
		//--- (b2World=>qb2World) Maintains an array of all active worlds, only useful for qb2DebugDrawPanel for the time being.
		//--- Weak keys allow the world to be garbage collected, and effectively automatically removed from the array.
		//--- The user should really never instantiate more than one world, but you never know I guess.
		qb2_friend static const worldDict:Dictionary = new Dictionary(true);

		/** Creates a new qb2World instance.
		 */
		public function qb2World()
		{
			b2Base.initialize(true);
			
			b2World.defaultContactListener = qb2InternalContactListener;
			b2World.defaultDestructionListener = qb2InternalDestructionListener;
			_worldB2 = new b2World(new V2(), true);
			_world = this;
			
			worldDict[_worldB2] = this;
			
			gravity = new amVector2d();
			
			//--- Just manually set this stuff, since this body isn't technically part of the world hierarchy.
			_background._world = this;
			_background._parent = this;
			_background._bodyB2 = _worldB2.m_groundBody;
		}
		
		public function get b2_world():b2World
			{  return _worldB2;  }
			
		public function get gravityZ():Number
			{ return _gravityZ; }
		public function set gravityZ(value:Number):void 
		{
			_gravityZ = value;
			
			_globalFrictionZRevision++;
		}
		private var _gravityZ:Number = 0;
		
		public function get gravity():amVector2d
			{ return _gravity; }
		public function set gravity(value:amVector2d):void 
		{
			if ( _gravity )  _gravity.removeEventListener(amUpdateEvent.ENTITY_UPDATED, gravityUpdated);
			_gravity = value;
			_gravity.addEventListener(amUpdateEvent.ENTITY_UPDATED, gravityUpdated);
			gravityUpdated(null);
		}
		private var _gravity:amVector2d = null;
		
		private function gravityUpdated(evt:amUpdateEvent):void
			{  _worldB2.SetGravity(new V2(_gravity.x, _gravity.y));  }
		
		public function get continuousPhysics():Boolean
			{  return _worldB2.m_continuousPhysics;  }
		public function set continuousPhysics(bool:Boolean):void
			{  _worldB2.m_continuousPhysics = bool;  }
		
		qb2_friend function addDelayedCall(object:qb2Object, closure:Function, ... args):void
		{
			var delayedCall:qb2InternalDelayedCall = new qb2InternalDelayedCall();
			delayedCall.object = object;
			delayedCall.closure = closure;
			delayedCall.args = args;
			if ( object is qb2Shape )
			{
				(object as qb2Shape).flaggedForDestroy = true; // shape won't send any more contact events in this pass.
			}
			
			delayedCalls.push(delayedCall);
		}

		/** If set, objects in the world will be drawn to the context according to the values in qb2DebugDrawSettings.
		 * This is not meant as a polished rendering solution, but is very useful for quick debugging.
		 * @default null
		 */
		public var debugDrawContext:Graphics = null;
		
		/** If set, debug mouse dragging is enabled using the mouseX/Y of the given object. This means every dynamic object is draggable.  It is called
		 * debug because it is not meant as a robust solution for most games or simulations. Usually you would set this to the stage or another high-level display list object.
		 * @default null
		 * @see #debugDragAccel
		 * @warning Make sure the display object you set this to can receive MouseEvent's.
		 */
		public function get debugDragSource():InteractiveObject
			{  return _debugDragSource;  }
		public function set debugDragSource(interactiveObject:InteractiveObject):void
		{
			mouseDown = false;
			
			if ( _debugDragSource )
			{
				if ( _debugDragSource.stage )
					_debugDragSource.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseEvent);
				_debugDragSource.removeEventListener(MouseEvent.MOUSE_DOWN, mouseEvent);
			}
			
			_debugDragSource = interactiveObject;

			if ( _debugDragSource )
			{
				if ( !containsObject(debugMouseJoint) )
				{
					debugMouseJoint.object = null;
					addObject(debugMouseJoint);
				}
					
				_debugDragSource.addEventListener(MouseEvent.MOUSE_DOWN, mouseEvent, false, 0, true);
			}
			else
			{
				if ( containsObject(debugMouseJoint) )
				{
					removeObject(debugMouseJoint);
				}
			}
		}
		private var _debugDragSource:InteractiveObject;
		
		
		/** If debugDragSource is set to something meaningful, this value determines how forcefully the mouse can drag bodies.
		 * It is scaled by the mass of the body being dragged, so all bodies will be dragged at the same speed.
		 * @default 1000.0
		 * @see #debugDragSource
		 */
		public var debugDragAccel:Number = 1000.0;
		
		//--- Internal variables for mouse tracking.
		private var mouseDown:Boolean = false;
		private const debugMouseJoint:qb2MouseJoint = new qb2MouseJoint();
		
		/** The relationship between the physics world ("meters") and the Flash world (pixels). Box2D is tuned to work with values much
		 * smaller than the average resolutions of Flash apps.  30 pixels per 1 meter seems to be a good ratio for most simulations.
		 * NOTE: Unless otherwise noted, ALL units passed back and forth through qb2World are in pixels, for convenience. qb2World automatically does the conversion to "meters".
		 * @default 30.0
		 */
		public function get pixelsPerMeter():Number
			{	return _pixelsPerMeter;  }
		public function set pixelsPerMeter(value:Number):void
			{	_pixelsPerMeter = value;  }
		qb2_friend var _pixelsPerMeter:Number  = 30.0;
		
		//--- For internal use...listens for mouse events if _debugDragSource is set to something meaningful.
		private function mouseEvent(evt:MouseEvent):void
		{
			if ( !_debugDragSource )
			{
				mouseDown = false;
				return;
			}
			
			mouseDown = evt.type == MouseEvent.MOUSE_DOWN;
			
			if ( mouseDown )
			{
				_debugDragSource.stage.addEventListener(MouseEvent.MOUSE_UP, mouseEvent, false, 0, true);
			}
			else
			{
				_debugDragSource.stage.removeEventListener(MouseEvent.MOUSE_UP, mouseEvent);
			}
		}

		private function mouseDrag():void
		{
			// mouse press
			if( _debugDragSource && mouseDown && !debugMouseJoint.object )
			{
				var rigid:qb2IRigidObject = null;
				
				var mousePoint:amPoint2d = new amPoint2d(_debugDragSource.mouseX, _debugDragSource.mouseY);
				var rigids:Vector.<qb2IRigidObject> = this.getRigidsAtPoint(mousePoint, 1, -1, true);
				
				if ( rigids && rigids[0].debugMouseActive )
				{
					rigid = rigids[0];
				}
				else if( rigids )
				{
					rigids = this.getRigidsAtPoint(mousePoint, uint.MAX_VALUE, -1, true);
					for (var i:int = 0; i < rigids.length; i++) 
					{
						if ( rigids[i].debugMouseActive )
						{
							rigid = rigids[i];
							break;
						}
					}
				}
				
				if ( rigid )
				{
					debugMouseJoint.object = rigid;
					if ( !containsObject(debugMouseJoint) ) // a world.removeAllObjects(), for example, could remove this joint inadvertently.
						addObject(debugMouseJoint);
					debugMouseJoint.setWorldAnchor(mousePoint);
					debugMouseJoint.maxForce = (rigid.mass + rigid.attachedMass) * debugDragAccel;
					setObjectIndex(debugMouseJoint, numObjects - 1); // make joint be drawn on top of everything else...this could be done every frame to be guaranteed always on top, but that prolly costs more than it's worth.
				}
			}

			if( debugMouseJoint.object && (!mouseDown || !_debugDragSource || !debugMouseJoint.object.world) )
			{
				debugMouseJoint.object = null;
			}

			if( debugMouseJoint.object )
			{
				debugMouseJoint.worldTarget.set(_debugDragSource.mouseX, _debugDragSource.mouseY);
			}
		}
		
		/** Whether or not start() has been called.
		 * @default false
		 * @see #start()
		 */
		public function get running():Boolean
			{  return _running;  }
		private var _running:Boolean = false;
	
		/** Starts the simulation by registering an Event.ENTER_FRAME on an internal dummy Sprite, which calls step().
		 * If you want to operate on an frequency different than your display rate, set up a timer and call step() yourself.
		 * @see #stop()
		 * @see #step()
		 */
		public function start():void
			{  _running = true;  lastTime = getTimer() / 1000;  eventer.addEventListener(Event.ENTER_FRAME, enterFrame, false, 0, true);  }
		
		/** Stops the simulation by unregistering the Event.ENTER_FRAME started with start().
		 * @see #start()
		 * @see #step()
		 */
		public function stop():void
			{  _running = false;  eventer.removeEventListener(Event.ENTER_FRAME, enterFrame);  }
		
		//--- This function is used as a middle man so that the outside world only sees step() without the
		//--- Event parameter input, which might be a little confusing if you just wanted to update manually.
		private function enterFrame(evt:Event):void
		{
			var currTime:Number = getTimer() / 1000;
			var timeStep:Number = realtimeUpdate ? amUtils.constrain(currTime - lastTime, 0, maximumRealtimeStep) : defaultTimeStep;
			
			step(timeStep, defaultPositionIterations, defaultVelocityIterations);
			
			lastTime = currTime;
		}
		
		/** The last time step that was used to advance the physics world in step().  This can change for each pass if realTimeUpdate == true
		 * @default 0
		 * @see #step()
		 * @see #realTimeUpdate
		 */
		public function get lastTimeStep():Number
			{  return _lastTimeStep;  }
		private var _lastTimeStep:Number = 0;
		
		/** The amount of time in seconds that has passed in the physics world since the simulation started.
		 * That is, the number of times step() has been called multiplied by the time step used on each call.
		 * @default 0
		 */
		public function get clock():Number
			{  return timer;  }
			
		private var timer:Number = 0;
		
		/** Updates the physics world. This includes processing debug mouse input, drawing debug graphics, updating fps, calling pre/postCallback(), and updating sprite/actor positions (if applicable).
		 * @see #defaultTimeStep
		 * @see #realtimeUpdate
		 */
		public function step( timeStep:Number = 1/30.0, positionIterations:uint = 3, velocityIterations:uint = 8 ):void
		{
			for (var key:* in preEventers)
			{
				var dispatcher:qb2Object = key as qb2Object;
				var preEvent:qb2UpdateEvent = getCachedEvent("preUpdate");
				preEvent._object = dispatcher;
				dispatcher.dispatchEvent(preEvent);
			}
			
			mouseDrag();
			
			_lastTimeStep = timeStep;
			timer += _lastTimeStep;
	
			processingBox2DStuff = true;
				b2Base.lib.b2World_Step(_worldB2._ptr, timeStep, velocityIterations, positionIterations);
			processingBox2DStuff = false;
			
			//--- Go through the changes made by the user to the physics world (if any) inside contact callbacks.
			//--- These are delayed until now because changing things in the middle of a timestep is not allowed in Box2D.
			for ( var i:int = 0; i < delayedCalls.length; i++ )
			{
				var delayedCall:qb2InternalDelayedCall = delayedCalls[i];
				
				var makeTheCall:Boolean = true; // the call isn't made if it appears it is for destroying a box2d object that was already destroyed implicitly.
				var object:qb2Object = delayedCall.object;
				var args:Array = delayedCall.args;
				
				if ( object is qb2Shape )
				{
					(object as qb2Shape).flaggedForDestroy = false;
					
					if ( args[0] is b2Fixture)
					{
						makeTheCall = (args[0] as b2Fixture).GetBody().m_fixtureCount > 0;
					}
				}
				else if ( object is qb2Joint )
				{
					if ( args[0] is b2Joint )
					{
						makeTheCall = (args[0] as b2Joint).m_userData != qb2InternalDestructionListener.JOINT_DESTROYED_IMPLICITLY;
					}
				}
				
				if( makeTheCall )
					delayedCall.closure.apply(null, args);
					
				if ( object is qb2Tangible && (object as qb2Tangible)._bodyB2 )
				{
					(object as qb2Tangible).rigid_recomputeBodyB2Mass();
				}
			}
			delayedCalls.length = 0;
			
			update();
			
			if ( debugDrawContext )
			{
				debugDrawContext.clear();
				drawDebug(debugDrawContext);
			}
			
			//--- Give the user a chance to do some logic.
			for ( key in postEventers)
			{
				dispatcher = key as qb2Object;
				var postEvent:qb2UpdateEvent = getCachedEvent("postUpdate");
				postEvent._object = dispatcher;
				dispatcher.dispatchEvent(postEvent);
			}
		}
		
		public function get totalNumPolygons():uint
			{  return _totalNumPolygons;  }
		qb2_friend var _totalNumPolygons:uint  = 0;
		
		public function get totalNumCircles():uint
			{  return _totalNumCircles;  }
		qb2_friend var _totalNumCircles:uint  = 0;
		
		public function get totalNumJoints():uint
			{  return _totalNumJoints;  }
		qb2_friend var _totalNumJoints:uint = 0;
		
		public override function removeObject(object:qb2Object):qb2ObjectContainer
		{
			if ( object == _background )  throw new Error("Background body cannot be removed from the world");
			return super.removeObject(object);
		}
		
		public override function clone():qb2Object
		{
			throw new Error("A qb2World cannot be cloned.");
			return null;
		}
		
		qb2_friend function registerGlobalTerrain(terrain:qb2Terrain):void
		{
			terrain.addEventListener(qb2ContainerEvent.INDEX_CHANGED, terrainIndexChanged, false, 0, true);
			
			addTerrainToList(terrain);
		}
		
		private function terrainIndexChanged(evt:qb2ContainerEvent):void
		{
			var terrain:qb2Terrain = evt.childObject as qb2Terrain;
			
			_globalTerrainList.splice(_globalTerrainList.indexOf(terrain), 1);
			
			addTerrainToList(terrain);
		}
		
		private function addTerrainToList(terrain:qb2Terrain):void
		{
			if ( !_globalTerrainList )
			{
				_globalTerrainList = new Vector.<qb2Terrain>();
				_globalTerrainList.push(terrain);
			}
			else
			{
				var inserted:Boolean = false;
				for (var i:int = 0; i < _globalTerrainList.length; i++) 
				{
					var ithTerrain:qb2Terrain = _globalTerrainList[i];
					
					if ( terrain.isBelow(ithTerrain) )
					{
						inserted = true;
						_globalTerrainList.splice(i, 0, terrain);
						break;
					}
				}
				
				if ( !inserted )
				{
					_globalTerrainList.push(terrain);
				}
			}
			
			if ( terrain.ubiquitous )
			{
				_globalFrictionZRevision++;
			}
		}
		
		qb2_friend function unregisterGlobalTerrain(terrain:qb2Terrain):void
		{
			_globalTerrainList.splice(_globalTerrainList.indexOf(terrain), 1);
			
			if ( !_globalTerrainList.length )
			{
				_globalTerrainList = null;
			}
			
			terrain.removeEventListener(qb2ContainerEvent.INDEX_CHANGED, terrainIndexChanged);
			
			if ( terrain.ubiquitous )
			{
				_globalFrictionZRevision++;
			}
		}
		
		qb2_friend var _globalTerrainList:Vector.<qb2Terrain> = null;
		
		qb2_friend var _globalFrictionZRevision:int = 0;
		
		qb2_friend var _frictionZRevisionDict:Dictionary = new Dictionary(true);
		
		
		public override function toString():String 
			{  return qb2DebugTraceSettings.formatToString(this, "qb2World");  }
	}
}