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

package TopDown.loaders 
{
	import As3Math.consts.TO_RAD;
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import QuickB2.loaders.*;
	import QuickB2.loaders.proxies.*;
	import QuickB2.misc.qb2UnitConverter;
	import QuickB2.objects.*;
	import TopDown.ai.*;
	import TopDown.loaders.proxies.*;
	import TopDown.objects.*;
	import TopDown.carparts.*;
	
	import TopDown.td_friend;
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdFlashLoader extends qb2FlashLoader
	{		
		private static function applyTireTag(tire:tdTire, tireTag:DisplayObject):void
		{
			if ( !defaultValue(tireTag["friction"]) )         tire.friction        = parseFloat(tireTag["friction"]);
			if ( !defaultValue(tireTag["rollingFriction"]) )  tire.rollingFriction = parseFloat(tireTag["rollingFriction"]);
			if ( !defaultValue(tireTag["mass"]) )             tire.mass            = parseFloat(tireTag["mass"]);
			
			if ( !defaultValue(tireTag["canTurn"]) )   tire.canTurn          = tireTag["canTurn"]  == "true";
			if ( !defaultValue(tireTag["isDriven"]) )  tire.isDriven         = tireTag["isDriven"] == "true";
			if ( !defaultValue(tireTag["canBrake"]) )  tire.canBrake         = tireTag["canBrake"] == "true";
			if ( !defaultValue(tireTag["flippedTurning"]) )  tire.flippedTurning         = tireTag["flippedTurning"] == "true";
		}
		
		private static function applyCarBodyTag(carBody:tdCarBody, carBodyTag:DisplayObject):void
		{
			if ( !defaultValue(carBodyTag["maxTurnAngle"]) )     carBody.maxTurnAngle    = parseFloat(carBodyTag["maxTurnAngle"]) * TO_RAD;
			if ( !defaultValue(carBodyTag["zCenterOfMass"]) )    carBody.zCenterOfMass   = parseFloat(carBodyTag["zCenterOfMass"]);
			if ( !defaultValue(carBodyTag["tractionControl"]) )  carBody.tractionControl = carBodyTag["canBrake"] == "true";
		}
		
		private static function applyTrannyTag(tranny:tdTransmission, trannyTag:DisplayObject):void
		{
			if ( !defaultValue(trannyTag["torqueConversion"]) )  tranny.torqueConversion    = parseFloat(trannyTag["torqueConversion"]);
			if ( !defaultValue(trannyTag["differential"]) )      tranny.differential   = parseFloat(trannyTag["differential"]);
			if ( !defaultValue(trannyTag["shiftTime"]) )         tranny.shiftTime = parseFloat(trannyTag["shiftTime"]);
			if ( !defaultValue(trannyTag["efficiency"]) )        tranny.efficiency = parseFloat(trannyTag["efficiency"]);
			if ( !defaultValue(trannyTag["transmissionType"]) )  tranny.transmissionType = trannyTag["transmissionType"] == "automatic" ? tdTransmission.TRANNY_AUTOMATIC : tdTransmission.TRANNY_MANUAL;
		}
		
		private static function isSelfTireTag(potentialTag:DisplayObject):Boolean
			{  return potentialTag.hasOwnProperty("rollingFriction");  }
		
		protected override function foundUserProxy(host:qb2Object, proxy:qb2ProxyUserObject):void
		{
			var i:int;
			
			if ( host is tdCarBody )
			{
				var carBody:tdCarBody = host as tdCarBody;
				if ( proxy is tdProxyTire )
				{
					var tireProxy:tdProxyTire = proxy as tdProxyTire;
					var saveRot:Number = tireProxy.rotation;
					tireProxy.rotation = 0;
					var newTire:tdTire = new tdTire(new amPoint2d(tireProxy.x, tireProxy.y), tireProxy.width, tireProxy.height / 2);
					
					if ( isSelfTireTag(tireProxy) )
						applyTireTag(newTire, tireProxy);
						
					newTire.actor = tireProxy;
					tireProxy.actualObject = newTire;
					carBody.addObject(newTire);
				}
			}
			else if ( host is tdMap )
			{
				var map:tdMap = host as tdMap;
				
				if ( proxy is tdProxyTrack )
				{
					var proxyTrack:tdProxyTrack = proxy as tdProxyTrack;
					//popUp(proxyTrack);
					var localRect:Rectangle = proxyTrack.getRect(proxyTrack);
					
					var topPoint:Point = new Point(0, -localRect.height / 2);
					var botPoint:Point = new Point(0, localRect.height / 2);
					var matrix:Matrix = proxyTrack.transform.matrix;
				//	matrix.invert();
					topPoint = matrix.transformPoint(topPoint);
					botPoint = matrix.transformPoint(botPoint);
					
					proxyTrack.parent.removeChild(proxyTrack);
					
					var end:amPoint2d = amPoint2d.newFromFlash(topPoint);
					var beg:amPoint2d = amPoint2d.newFromFlash(botPoint);
					
					var track:tdTrack = new tdTrack(beg, end);
					
					proxyTrack.rotation = 0;
					track.width = proxyTrack.width;
					if ( !defaultValue(proxyTrack["speedLimit"]) )
					{
						track.speedLimit = qb2UnitConverter.milesPerHour_to_metersPerSecond(parseFloat(proxyTrack.speedLimit));
					}
					proxyTrack.actualObject = track;
					map.addObject(track);
				}
			}
		}
		
		protected override function applyTag(object:qb2Object, tag:qb2Proxy):void
		{
			super.applyTag(object, tag);
			
			if ( object is tdCarBody )
			{
				var carBody:tdCarBody       = object as tdCarBody;
				
				if ( tag is tdProxyCarBody )
				{
					var carBodyTag:tdProxyCarBody = tag    as tdProxyCarBody;
					applyCarBodyTag(carBody, carBodyTag);
				}
				else if ( tag is tdProxyTire )
				{
					var tireTag:tdProxyTire = tag    as tdProxyTire;
					
					for (var i:int = 0; i < carBody.tires.length; i++) 
					{
						var tire:tdTire = carBody.tires[i];
						applyTireTag(tire, tireTag);
					}
				}
				else if ( tag is tdProxyGearRatio )
				{
					if ( !carBody.tranny )  carBody.tranny = new tdTransmission();
					
					var ratioTag:tdProxyGearRatio = tag as tdProxyGearRatio;
					var tranny:tdTransmission = carBody.tranny;
					var ratios:Vector.<Number> = tranny.gearRatios;
					
					var gear:uint = ratioTag.gear;
					if ( ratios.length < gear +1 )
						ratios.length = gear + 1;
					ratios[gear] = ratioTag.gearRatio;
				}
				else if ( tag is tdProxyTransmission )
				{
					if ( !carBody.tranny )  carBody.tranny = new tdTransmission();
					
					applyTrannyTag(carBody.tranny, tag);
				}
				else if ( tag is tdProxyTorqueEntry )
				{
					if ( !carBody.engine )  carBody.engine = new tdEngine();
					
					var torqueTag:tdProxyTorqueEntry = tag as tdProxyTorqueEntry;
					var engine:tdEngine = carBody.engine;
					var curve:tdTorqueCurve = engine.torqueCurve;
					curve.addEntry(torqueTag.rpm, torqueTag.torque);
				}
			}
			else if ( object is tdMap )
			{
				var map:tdMap = object as tdMap;
				
				if ( tag is tdProxyMap )
				{
					var mapTag:tdProxyMap = tag as tdProxyMap;
				}				
				else if ( tag is tdProxyTrafficManager )
				{
					var trafficManProxy:tdProxyTrafficManager = tag as tdProxyTrafficManager;
					
					var tm:tdTrafficManager = map.trafficManager ? map.trafficManager : new tdTrafficManager();
					tm.spawnInterval = trafficManProxy.spawnInterval;
					tm.carSpawnChance = trafficManProxy.spawnChance;
					tm.maxNumCars = trafficManProxy.maxNumCars;
					
					var seeds:Array = [];
					initializeTrafficManagerSeeds(trafficManProxy.cars1, seeds);
					initializeTrafficManagerSeeds(trafficManProxy.cars2, seeds);
					initializeTrafficManagerSeeds(trafficManProxy.cars3, seeds);
					
					tm.carSeeds = seeds;
					
					map.trafficManager = tm;
				}
			}
			else if ( (tag is tdProxyTerrain) && (object is tdTerrain) )
			{
				var terrainTag:tdProxyTerrain = tag as tdProxyTerrain;
				var terrain:tdTerrain = object as tdTerrain;
				
				terrain.frictionZMultiplier = terrainTag.frictionZMultiplier
				terrain.rollingFrictionZMultiplier = terrain.rollingFrictionZMultiplier;
				terrain.rollingSkidColor = terrainTag.rollingSkidColor;
				terrain.slidingSkidColor = terrainTag.slidingSkidColor;
			}
		}
		
		private function initializeTrafficManagerSeeds(source:String, existingSeeds:Array):void
		{
			var split:Array = source.split(" ").join("").split(",");
			for (var i:int = 0; i < split.length; i++) 
			{
				var seed:String = split[i];
				if ( !seed )  continue;
				existingSeeds.push(seed);
			}
		}
		
		protected override function finishObject(object:qb2Object):void
		{
			super.finishObject(object);
			
			if ( object is tdCarBody )
			{
				// add stuff for controlling the car, or something
			}
			else if ( object is tdMap )
			{
				var map:tdMap = object as tdMap;
				/*if ( trackDict[map] )
				{
					var tracks:Vector.<tdTrack> = trackDict[map] as Vector.<tdTrack>;
					map.addTracks(tracks);
				}*/
			}			
		}
	}
}