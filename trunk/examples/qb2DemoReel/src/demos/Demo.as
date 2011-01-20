package demos
{
	import flash.display.*;
	import QuickB2.events.*;
	import QuickB2.objects.tangibles.*;

	/**
	 * Serves as the base class for all the demos, providing basic hooks and events.
	 * 
	 * @author Doug Koellmer
	 */
	public class Demo extends qb2Group
	{
		public function Demo() 
		{
			this.actor = new Sprite();
			
			this.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, addedOrRemoved, false, 0, true);
			this.addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved, false, 0, true);
		}
		
		/// Lets a demo know when it should clean stuff up.
		protected function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			
		}
		
		protected function get stageWidth():Number
			{  return Main.singleton.stage.stageWidth;  }
			
		protected function get stageHeight():Number
			{  return Main.singleton.stage.stageHeight;  }
			
		protected function get stage():Stage
			{  return Main.singleton.stage;  }
	}
}