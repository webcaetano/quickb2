package demos 
{
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.display.DisplayObjectContainer;
	import QuickB2.events.*;
	import QuickB2.misc.qb2Keyboard;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import TopDown.ai.*;
	import TopDown.ai.brains.*;
	import TopDown.ai.controllers.*;
	import TopDown.carparts.*;
	import TopDown.debugging.*;
	import TopDown.objects.*;
	import TopDown.stock.*;
	
	/**
	 * Demonstrates how to use qb2FlashLoader to load in some assets made in FlashCS5.
	 * 
	 * @author Doug Koellmer
	 */
	public class CarDriving extends Demo
	{
		private var playerCar:tdCarBody = new tdCarBody();
		
		private var map:tdMap = new tdMap(); // special subclass of qb2Group that you can add tracks and other car-related goodies to.
		
		private var debugPanel:tdDebugPanel = new tdDebugPanel();  // special debug panel for the TopDown library.
		
		private var trafficManager:tdTrafficManager = new tdTrafficManager();
		
		public function CarDriving() 
		{			
			var center:amPoint2d = new amPoint2d(stage.stageWidth / 2, stage.stageHeight / 2);
			
			//--- Make a terrain that encompasses the whole map, basically so skids are drawn everywhere.
			var defaultTerrain:tdTerrain = new tdTerrain(true /*ubiquitous*/ );
			defaultTerrain.frictionZMultiplier = 1.5;
			map.addObject(defaultTerrain);
			
			//--- Make a little icy pond.
			var icyPatch:tdTerrain = new tdTerrain();
			icyPatch.frictionZMultiplier = .1;
			icyPatch.slidingSkidColor = 0x33ffff;
			icyPatch.position.set(stageWidth * 1.5, stageHeight * 1.5);
			icyPatch.addObject(qb2Stock.newCircleShape(new amPoint2d(), 200, 0));
			map.addObject(icyPatch);
			
			//--- Set up some properties for the tracks, the "roads" that traffic will drive on.
			var roadWid:Number = 100;
			var rectWidth:Number = stageWidth*2;
			var rectHeight:Number = stageHeight*2;
			var speedLimit:Number = 10;
			
			//--- Tracks can only be meaningfully added to a special subclass of qb2Group, called tdMap.
			map.addObjects(tdTrackStock.newTrackRect(center, roadWid, roadWid, rectWidth / 2+roadWid, rectHeight / 2+roadWid, false, speedLimit));
			map.addObjects(tdTrackStock.newTrackRect(center, rectWidth - roadWid, rectHeight-roadWid, roadWid*2, roadWid*2, true, speedLimit));
			map.addObjects(tdTrackStock.newTrackRect(center, rectWidth + roadWid, rectHeight+roadWid, roadWid, roadWid, false, speedLimit));
			addObject(map);
			
			//--- Give the car geometry and mass.  Provide junk in the trunk so that the car has oversteer and can do handbrake turns more easily.
			var carWidth:Number = 60;
			var carHeight:Number = 90;
			playerCar.addObject
			(
				qb2Stock.newRectShape(new amPoint2d(0, 0), carWidth, carHeight),
				qb2Stock.newCircleShape(new amPoint2d(0, carHeight/4), carWidth/2)
			);
			playerCar.mass = 1000;  // give the car a realistic mass of 1000 kilograms.
			playerCar.tractionControl = false; // let the tire's driven wheels spin freely
			playerCar.position.copy(center);
			
			//--- Set up some variables for tire properties and add four tires.
			//--- Here we're making a front-wheel drive car, with rear-wheel braking only (hand brakes).
			var tireFriction:Number = 2.0; // friction coefficient...this is a bit high for everyday life (like nascar or something).
			var tireRollingFriction:Number = 1;  // again a little high for real life, but good for games cause the car comes to a stop a lot faster.
			var tireWidth:Number = 7;
			var tireRadius:Number = 10;
			playerCar.addObject
			(
				new tdTire(new amPoint2d(-carWidth/2, -carHeight/3), tireWidth, tireRadius, true /*driven*/,  true /*turns*/, false /*brakes*/, tireFriction, tireRollingFriction),
				new tdTire(new amPoint2d( carWidth/2, -carHeight/3), tireWidth, tireRadius, true /*driven*/,  true /*turns*/, false /*brakes*/, tireFriction, tireRollingFriction),
				new tdTire(new amPoint2d( carWidth/2,  carHeight/3), tireWidth, tireRadius, false /*driven*/, false /*turns*/, true  /*brakes*/, tireFriction, tireRollingFriction),
				new tdTire(new amPoint2d(-carWidth/2,  carHeight/3), tireWidth, tireRadius, false /*driven*/, false /*turns*/, true  /*brakes*/, tireFriction, tireRollingFriction)
			);
			
			//--- Set up keyboard controls for the car.
			var playerBrain:tdControllerBrain = new tdControllerBrain();
			playerBrain.addController(new tdKeyboardCarController(stage));
			playerCar.addObject(playerBrain);
			
			//--- Give the car an engine and transmission...both optional, but needed if you want the car to move under its own power.
			playerCar.addObject(new tdEngine(), new tdTransmission());
			
			//--- Gear ratios for the transmission, starting with reverse, then first, second, etc.
			playerCar.tranny.gearRatios = Vector.<Number>([3.5, 3.5, 3, 2.5, 2, 1.5, 1]);
			
			//--- A torque curve describes engine performance, in this case relating RPM to torque output in Nm.
			var curve:tdTorqueCurve = playerCar.engine.torqueCurve;
			curve.addEntry(1000, 300); // (engine outputs a maximum torque of 300 Nm at 1000 RPM.
			curve.addEntry(2000, 310);
			curve.addEntry(3000, 320);
			curve.addEntry(4000, 325);
			curve.addEntry(5000, 330); // (this is the maximum torque the engine can produce).
			curve.addEntry(6000, 325);
			curve.addEntry(7000, 320);
			
			//--- Add the car to the map.
			map.addObject(playerCar);
			
			//--- Make a plow looking car-thing.
			var plowCar:tdCarBody = playerCar.clone() as tdCarBody;
			var boundBox:amBoundBox2d = plowCar.getBoundBox(plowCar);
			var plowHead:qb2PolygonShape = qb2Stock.newRectShape(new amPoint2d(0, -boundBox.height / 2), boundBox.width * 1.5, 10, 1);
			plowHead.insertVertexAt(1, new amPoint2d(0, -boundBox.height / 2 - 5));
			plowHead.getVertexAt(0).y -= 10;
			plowHead.getVertexAt(2).y -= 10;
			plowCar.addObject(plowHead);
			
			//--- Make a peanut looking car.
			var peanutCar:tdCarBody = playerCar.clone() as tdCarBody;
			peanutCar.removeObjectAt(0);
			peanutCar.addObjectAt((peanutCar.getObjectAt(0).clone() as qb2Shape), 0);
			(peanutCar.getObjectAt(0) as qb2Shape).position.y = -(peanutCar.getObjectAt(0) as qb2Shape).position.y;
			
			//--- Make some kind of weird hoop car with additional back wheels and one front wheel;
			var hoopCar:tdCarBody = playerCar.clone() as tdCarBody;
			hoopCar.removeObjectAt(0);
			hoopCar.removeObjectAt(0);
			hoopCar.removeObjectAt(0);
			(hoopCar.getObjectAt(0) as tdTire).position.x = 0;
			(hoopCar.getObjectAt(0) as tdTire).position.y -= 30;
			hoopCar.addObjectAt(qb2Stock.newEllipticalArcBody(new amPoint2d(), new amVector2d(0, -70), 30, 12, 0, AM_PI * 2, 10, 1000), 0);
			hoopCar.addObject(hoopCar.lastObject(2).clone());
			hoopCar.addObject(hoopCar.lastObject(4).clone());
			(hoopCar.lastObject() as tdTire).position.y -= 25;
			(hoopCar.lastObject(1) as tdTire).position.y -= 25;
			
			//--- Configure the traffic manager.
			trafficManager.carSeeds = [playerCar, plowCar, peanutCar, hoopCar];  // manager will clone() instances of these cars to create traffic.
			trafficManager.maxNumCars = 3;          // can only be 3 traffic cars in the scene at any given time.
			map.trafficManager = trafficManager;
			
			//--- Make a prototype brain that the traffic manager will clone to provide intelligence to the traffic cars.
			var prototypeTrafficBrain:tdTrackBrain = new tdTrackBrain();
			prototypeTrafficBrain.antennaLength = 100;
			trafficManager.brainSeeds = [prototypeTrafficBrain];
			
			var box:qb2PolygonShape = qb2Stock.newRectShape(icyPatch.position.clone(), 50, 200, 300, RAD_15);
			box.frictionZ = 1;
			map.addObject(box);
			
			//--- Add some objects to drive into.
			var fence:qb2Group = new qb2Group();
			fence.frictionZ = 1.0; // make all the objects in the fence group have friction against the ground.
			var angleInc:Number = RAD_10;
			var rotPoint:amPoint2d = center.clone().incY( -200);
			var limit:int = AM_PI * 2 / angleInc;
			var postSize:Number = 20;
			var postMass:Number = 200;
			for (var i:int = 0; i < limit; i++) 
			{
				if ( i % 2 )
					fence.addObject(qb2Stock.newRectBody(rotPoint.rotatedBy(i * angleInc, center), postSize, postSize, postMass, i * angleInc));
				else
					fence.addObject(qb2Stock.newCircleBody(rotPoint.rotatedBy(i * angleInc, center), postSize/2, postMass));
			}
			map.addObject(fence);
			
			this.addEventListener(qb2UpdateEvent.PRE_UPDATE,  updateManager);
		}
		
		private function updateManager(evt:qb2UpdateEvent):void
		{
			//--- Tell the traffic manager where the field of view is.
			//--- Make the view a little larger so we don't see cars being spawned.
			var cameraPos:amPoint2d = cameraPoint;
			trafficManager.horizon.width  = stageWidth + 200;
			trafficManager.horizon.height = stageHeight + 200;
			trafficManager.horizon.center = new amPoint2d(cameraPos.x, cameraPos.y);
		}
		
		protected override function update():void
		{
			super.update();
			
			//var targetPos:amPoint2d = cameraTargetPoint;
			
			//--- Establish where the "camera" should be looking.  ( this gets a little laggy on slow computers).
			/*cameraTargetPoint.copy(playerCar.position);
			var leadLimit:Number = Math.min(stageWidth/2, stageHeight/2);
			var carLead:amVector2d = playerCar.linearVelocity.scaledBy(1000);
			var carLeadLength:Number = carLead.length;
			carLead.normalize().scaleBy(amUtils.constrain(carLeadLength, 0, leadLimit));
			cameraTargetPoint.translateBy(carLead);
			trace(carLead);*/
			
			
			//--- Just make it follow the player's position exactly, instead of leading it, which is choppy with all this gui stuff on screen.
			cameraPoint.copy(playerCar.position);
			cameraTargetPoint.copy(playerCar.position);
		}
		
		private var saveGravity:amVector2d = new amVector2d();
		
		//--- Have to change some things around when this demo is added to the world, such as gravity and collisions, and return it normal after.
		protected override function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				//--- Set realistic z gravity and zero x/y gravity.
				saveGravity.copy(this.world.gravity);
				this.world.gravity.set(0, 0);
				this.world.gravityZ = 9.8;
				
				stageWalls.contactCollidesWith = 0; // disable all contacts for the stage walls.
				(this.actor as DisplayObjectContainer).addChildAt(debugPanel, 0);
				debugPanel.alpha = 1;
				debugPanel.y = stageHeight - debugPanel.height;
			}
			else
			{
				//--- Leave the world's gravity the way we found it.
				this.world.gravity.copy(saveGravity);
				this.world.gravityZ = 0;
				
				//--- Put whole demo back where it should be.
				cameraTargetPoint.set(stageWidth / 2, stageHeight / 2);
				cameraTargetRotation = 0;
				
				stageWalls.contactCollidesWith = 0xffffff; // reenable all contacts for the stage walls.
				(this.actor as DisplayObjectContainer).removeChild(debugPanel);
			}
		}
		
		public override function resized():void
		{
			debugPanel.x = 0;
			debugPanel.y = stageHeight - debugPanel.height;
		}
	}
}