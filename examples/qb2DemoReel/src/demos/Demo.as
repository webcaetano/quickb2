package demos
{
	import As3Math.consts.TO_DEG;
	import As3Math.consts.TO_RAD;
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import flash.display.*;
	import QuickB2.events.*;
	import QuickB2.misc.acting.qb2FlashSpriteActor;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.qb2StageWalls;

	/**
	 * Serves as the base class for all the demos, basically providing some hooks to Main's properties.
	 * 
	 * @author Doug Koellmer
	 */
	public class Demo extends qb2Group
	{
		public function Demo() 
		{
			this.actor = new qb2FlashSpriteActor();
			
			this.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, addedOrRemoved);
			this.addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved);
		}
		
		public function get stageWalls():qb2StageWalls
			{  return Main.singleton.stageWalls;  }
		private var _stageWalls:qb2StageWalls = null;
		
		public function get cameraRotation():Number
			{  return Main.singleton.cameraRotation;  }
		public function set cameraRotation(value:Number):void
			{  Main.singleton.cameraRotation = value;  }
		
		public function get cameraTargetRotation():Number
			{  return Main.singleton.cameraTargetRotation;  }
		public function set cameraTargetRotation(value:Number):void
			{  Main.singleton.cameraTargetRotation = value;  }
			
		public function get cameraTargetPoint():amPoint2d
			{  return Main.singleton.cameraTargetPoint;  }
			
		public function get cameraPoint():amPoint2d
			{  return Main.singleton.cameraPoint;  }
			
		
		/// Lets a demo know when it should clean stuff up.
		protected virtual function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			
		}
		
		protected function get stageWidth():Number
			{  return Main.singleton.stage.stageWidth;  }
			
		protected function get stageHeight():Number
			{  return Main.singleton.stage.stageHeight;  }
			
		protected function get stage():Stage
			{  return Main.singleton.stage;  }
			
		public virtual function resized():void
		{
			
		}
	}
}