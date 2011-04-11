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
	import As3Math.geo2d.*;
	import Box2DAS.Dynamics.*;
	import flash.display.*;
	import flash.events.*;
	import QuickB2.effects.*;
	import QuickB2.misc.acting.qb2IActor;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.objects.tangibles.*;
	import revent.rIEventDispatcher;
	import surrender.srIDebugDrawable2d;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public interface qb2IRigidObject extends rIEventDispatcher, srIDebugDrawable2d
	{
		// INTERFACE FUNCTIONS
		function updateActor():void;
		
		function get numAttachedJoints():uint;
		
		function getAttachedJointAt(index:uint):qb2Joint;
		
		function get attachedMass():Number;
		
		function get position():amPoint2d;
		function set position(newPoint:amPoint2d):void;
		
		function getMetricPosition():amPoint2d;
		
		function get linearVelocity():amVector2d;
		function set linearVelocity(newVector:amVector2d):void;
		
		function get angularVelocity():Number;
		function set angularVelocity(radsPerSec:Number):void;
		
		function getNormal():amVector2d;
		
		function get rotation():Number;
		function set rotation(value:Number):void;
	
		function setTransform(point:amPoint2d, rotationInRadians:Number):qb2IRigidObject;
		
		function asTangible():qb2Tangible;
		
		function get b2_body():b2Body;
		
		
		
		
		
		
		
		// FUNCTIONS FOR qb2Tangible
		//function get effectFields():Vector.<qb2EffectField>;
		//function set effectFields(value:Vector.<qb2EffectField>):void 
			
		function get actor():qb2IActor;
		function set actor(newDO:qb2IActor):void;
		
		function testPoint(point:amPoint2d):Boolean;
		
		function rotateBy(radians:Number, origin:amPoint2d = null):qb2Tangible;
		
		function scaleBy(xValue:Number, yValue:Number, origin:amPoint2d = null, scaleMass:Boolean = true, scaleJointAnchors:Boolean = true, scaleActor:Boolean = true):qb2Tangible;
		
		function translateBy(vector:amVector2d):qb2Tangible;
		
		function distanceTo(otherTangible:qb2Tangible, outputVector:amVector2d = null, outputPointThis:amPoint2d = null, outputPointOther:amPoint2d = null, excludes:Array = null):Number;
		
		function get ancestorBody():qb2Body;
		
		function get density():Number;
		function set density(value:Number):void;

		function get mass():Number;
		function set mass(value:Number):void;

		function get surfaceArea():Number;
		
		function get metricSurfaceArea():Number;
		
		function get metricDensity():Number;
		function set metricDensity(value:Number):void;

		
		function get restitution():Number;
		function set restitution(value:Number):void;
		
		function get contactCategoryFlags():uint;
		function set contactCategoryFlags(bitmask:uint):void;
		
		function get contactMaskFlags():uint;
		function set contactMaskFlags(bitmask:uint):void;
		
		function get contactGroupIndex():int;
		function set contactGroupIndex(index:int):void;
		
		function get friction():Number;
		function set friction(value:Number):void;
		
		function get frictionZ():Number;
		function set frictionZ(value:Number):void;
		
		function get linearDamping():Number;
		function set linearDamping(value:Number):void;
		
		function get angularDamping():Number;
		function set angularDamping(value:Number):void;
		
		function get sliceFlags():uint;
		function set sliceFlags(value:uint):void;
			
		function turnSliceFlagOn(sliceFlagOrFlags:uint):qb2Tangible;
		function turnSliceFlagOff(sliceFlagOrFlags:uint):qb2Tangible;
		function isSliceFlagOn(sliceFlagOrFlags:uint):Boolean;
		function setSliceFlag(bool:Boolean, sliceFlagOrFlags:uint):qb2Tangible;
	
		function get isGhost():Boolean;
		function set isGhost(bool:Boolean):void;
		
		function get isKinematic():Boolean;
		function set isKinematic(bool:Boolean):void;
	
		function get hasFixedRotation():Boolean;
		function set hasFixedRotation(bool:Boolean):void;
		
		function get isBullet():Boolean;
		function set isBullet(bool:Boolean):void;
		
		function get allowSleeping():Boolean;
		function set allowSleeping(bool:Boolean):void;
		
		function get sleepingWhenAdded():Boolean;
		function set sleepingWhenAdded(bool:Boolean):void;
		
		function get isDebugDraggable():Boolean;
		function set isDebugDraggable(bool:Boolean):void;
		
		
		function get isSleeping():Boolean;
		
		function putToSleep():void;

		function wakeUp():void;
		
		function get centerOfMass():amPoint2d;
		
		function applyImpulse(atPoint:amPoint2d, impulseVector:amVector2d):void;
		
		function applyForce(atPoint:amPoint2d, forceVector:amVector2d):void;
		
		function applyTorque(torque:Number):void;
			
		function getWorldPoint(localPoint:amPoint2d, overrideWorldSpace:qb2Tangible = null):amPoint2d;
		
		function getLocalPoint(worldPoint:amPoint2d, overrideWorldSpace:qb2Tangible = null):amPoint2d;
		
		function getWorldVector(localVector:amVector2d, overrideWorldSpace:qb2Tangible = null):amVector2d;
		
		function getLocalVector(worldVector:amVector2d, overrideWorldSpace:qb2Tangible = null):amVector2d;
		
		function getWorldRotation(localRotation:Number, overrideWorldSpace:qb2Tangible = null):Number;
		
		function getLocalRotation(worldRotation:Number, overrideWorldSpace:qb2Tangible = null):Number;
		
		function getBoundBox(worldSpace:qb2Tangible = null):amBoundBox2d;
		
		function getBoundCircle(worldSpace:qb2Tangible = null):amBoundCircle2d;
		
		function getLinearVelocityAtPoint(point:amPoint2d):amVector2d;
		
		function getLinearVelocityAtLocalPoint(point:amPoint2d):amVector2d;
		
		
		
		
		
		// FUNCTIONS in qb2Object/qb2EventDispatcher (EventDispatcher functions are pulled in by 'extends IEventDispatcher' at the top.
		
		function getProperty(propertyName:String):*;
		function setProperty(propertyName:String, value:*, takesOwnership:Boolean = true):qb2Object;
		
		function get flags():uint;
		
		function turnFlagOn(flag:uint, takesOwnership:Boolean = true):qb2Object;
		
		function turnFlagOff(flag:uint, takesOwnership:Boolean = true):qb2Object;
		
		function isFlagOn(flag:uint):Boolean;
		
		function ownsFlag(flag:uint):Boolean;
		
		function ownsProperty(propertyName:String):Boolean;
		
		function get joinsInDeepCloning():Boolean;
		function set joinsInDeepCloning(bool:Boolean):void;
		
		function get joinsInDebugDrawing():Boolean;
		function set joinsInDebugDrawing(bool:Boolean):void;
		
		function get joinsInUpdateChain():Boolean;
		function set joinsInUpdateChain(bool:Boolean):void;
		
		function get parent():qb2ObjectContainer;

		function get world():qb2World;
		
		function removeFromParent():void;
		
		function clone(deep:Boolean = true):qb2Object;
		
		function isDescendantOf(possibleAncestor:qb2ObjectContainer):Boolean;
		
		function isDescendantOfType(possibleAncestorType:Class):Boolean;
		
		function getAncestorOfType(ancestorType:Class):qb2ObjectContainer;
		
		function getCommonAncestor(otherObject:qb2Object):qb2ObjectContainer;
		
		function isAbove(otherObject:qb2Object):Boolean;
		
		function isBelow(otherObject:qb2Object):Boolean;
		
		function get worldPixelsPerMeter():Number;
		
		function toString():String;
	}
}