package demos 
{
	import As3Math.consts.*;
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import com.greensock.events.LoaderEvent;
	import com.greensock.loading.data.SWFLoaderVars;
	import com.greensock.loading.SWFLoader;
	import com.greensock.plugins.AutoAlphaPlugin;
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.getDefinitionByName;
	import QuickB2.events.*;
	import QuickB2.misc.qb2Keyboard;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import TopDown.ai.*;
	import TopDown.ai.brains.*;
	import TopDown.ai.controllers.*;
	import TopDown.carparts.*;
	import TopDown.debugging.*;
	import TopDown.loaders.tdFlashLoader;
	import TopDown.objects.*;
	import TopDown.stock.*;
	
	/**
	 * Demonstrates the basics of working with cars using the TopDown library.
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
			
			//--- Give the car geometry and mass.  Provide junk in the trunk so that the car has oversteer and can do handbrake turns more easily.
			var carWidth:Number = 60;
			var carHeight:Number = 90;
			playerCar.addObject
			(
				qb2Stock.newRectShape(new amPoint2d(0, 0), carWidth, carHeight),
				qb2Stock.newCircleShape(new amPoint2d(0, carHeight/4), carWidth/2)
			);
			playerCar.mass = 1000;  // give the car a realistic mass of 1000 kilograms.
			playerCar.position.copy(center);
			
			//--- Set up some variables for tire properties and add four tires.
			var tireFriction:Number = 2.0; // friction coefficient...this is a bit high for everyday life (like nascar or something).
			var tireRollingFriction:Number = 1;  // again a little high for real life, but good for games cause the car comes to a stop a lot faster.
			var tireWidth:Number = 7;
			var tireRadius:Number = 10;
			playerCar.addObject
			(
				new tdTire(new amPoint2d(-carWidth/2, -carHeight/3), tireWidth, tireRadius, true /*driven*/,  true /*turns*/,  false /*brakes*/, tireFriction, tireRollingFriction),
				new tdTire(new amPoint2d( carWidth/2, -carHeight/3), tireWidth, tireRadius, true /*driven*/,  true /*turns*/,  false /*brakes*/, tireFriction, tireRollingFriction),
				new tdTire(new amPoint2d( carWidth/2,  carHeight/3), tireWidth, tireRadius, true /*driven*/, false /*turns*/, true  /*brakes*/, tireFriction, tireRollingFriction),
				new tdTire(new amPoint2d(-carWidth/2,  carHeight/3), tireWidth, tireRadius, true /*driven*/, false /*turns*/, true  /*brakes*/, tireFriction, tireRollingFriction)
			);
			
			//--- Set up keyboard controls for the car.
			var playerBrain:tdControllerBrain = new tdControllerBrain();
			playerBrain.addController(new tdKeyboardCarController(Main.singleton.stage));
			playerCar.brain = playerBrain;
			
			//--- Give the car an engine and transmission...both optional, but needed if you want the car to move under its own power.
			playerCar.engine = new tdEngine();
			playerCar.tranny = new tdTransmission();
			
			//--- Gear ratios for the transmission, starting with reverse, then first, second, etc.
			playerCar.tranny.gearRatios = Vector.<Number>([3.5, 3.5, 3, 2.5, 2, 1.5, 1]);
			
			//--- A torque curve describes engine performance, in this case relating RPM to torque output in Nm.
			var curve:tdTorqueCurve = playerCar.engine.torqueCurve;
			curve.addEntry(1000, 300); // (engine outputs a maximum torque of 300 Nm at 1000 RPM.
			curve.addEntry(2000, 310);
			curve.addEntry(3000, 320);
			curve.addEntry(4000, 325);
			curve.addEntry(5000, 330); // (this would be the maximum torque this engine can produce).
			curve.addEntry(6000, 325);
			curve.addEntry(7000, 320);
			
			//--- Add the car to the map.
			map.addObject(playerCar);
			
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
			
			trafficManager.carSeeds = [playerCar];  // manager will clone() an instance of the player's car to make new cars.
			trafficManager.maxNumCars = 1;
			map.trafficManager = trafficManager;
			
			var terrain:tdTerrain = new tdTerrain();
			terrain.frictionZMultiplier = 0;
			terrain.addObject(qb2Stock.newCircleShape(new amPoint2d(), 100, 0));
			addObject(terrain);
			
			var circ:qb2CircleShape = qb2Stock.newCircleShape( new amPoint2d(), 30, 1000);
			circ.frictionZ = 1;
			addObject(circ);
			
			this.addEventListener(qb2UpdateEvent.PRE_UPDATE,  updateManager);
			this.addEventListener(qb2UpdateEvent.POST_UPDATE, updateCamera);
		}
		
		private function updateManager(evt:qb2UpdateEvent):void
		{
			//--- Tell the traffic manager where the field of view is.
			//--- Make the view a little larger so we don't see cars being spawned.
			var cameraPos:amPoint2d = Main.singleton.cameraPoint;
			trafficManager.horizon.width  = stageWidth + 200;
			trafficManager.horizon.height = stageHeight + 200;
			trafficManager.horizon.center = new amPoint2d(cameraPos.x, cameraPos.y);
		}
		
		private var carSpeedBase:Number = 20;
		
		private function updateCamera(evt:qb2UpdateEvent):void
		{
			var targetPos:amPoint2d = Main.singleton.cameraTargetPoint;
			
			//--- Establish where the "camera" should be looking.
			var cameraLead:Number = Math.min(stageWidth, stageHeight) * .75;
			targetPos.copy(playerCar.position);
			var carSpeed:Number = amUtils.constrain(playerCar.linearVelocity.length, 0, carSpeedBase);
			var ratio:Number = carSpeed / carSpeedBase;
			var cameraLeadVec:amVector2d = playerCar.linearVelocity.lengthSquared ? playerCar.linearVelocity.clone() : playerCar.getNormal();
			cameraLeadVec.setLength(ratio * cameraLead);
			targetPos.translateBy(cameraLeadVec);
			
			//Main.singleton.cameraTargetRotation = -playerCar.rotation;
		}
		
		private var saveGravity:amVector2d = new amVector2d();
		
		//--- Have to change some things around when this demo is added to the world, such as gravity and collisions, and return it normal after.
		protected override function addedOrRemoved(evt:qb2AddRemoveEvent):void
		{
			if ( evt.type == qb2AddRemoveEvent.ADDED_TO_WORLD )
			{
				//--- Set realistic z gravity and zero x/y gravity.
				saveGravity.copy(this.world.gravity);
				this.world.gravity.set(0, 0);
				this.world.gravityZ = 9.8;
				
				Main.singleton.stageWalls.contactCollidesWith = 0; // disable all contacts for the stage walls.
				Main.singleton.stage.addChild(debugPanel);
				debugPanel.alpha = 1;
				debugPanel.y = stageHeight - debugPanel.height;
			}
			else
			{
				//--- Leave the world's gravity the way we found it.
				this.world.gravity.copy(saveGravity);
				this.world.gravityZ = 0;
				
				//--- Put whole demo back where it should be.
				Main.singleton.cameraTargetPoint.set(stageWidth / 2, stageHeight / 2);
				Main.singleton.cameraTargetRotation = 0;
				
				Main.singleton.stageWalls.contactCollidesWith = 0xffffff; // reenable all contacts for the stage walls.
				Main.singleton.stage.removeChild(debugPanel);
			}
		}
	}
}