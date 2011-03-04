package demos 
{
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import QuickB2.effects.qb2PlanetaryGravityField;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * This demo just looks cool :)
	 * @author Doug Koellmer
	 */
	public class Planets extends Demo
	{
		public function Planets() 
		{
			//--- Just one simple field to get a pretty dynamic effect.
			var planetaryGravityField:qb2PlanetaryGravityField = new qb2PlanetaryGravityField();
			addObject(planetaryGravityField);
			
			//--- Add a really heavy square that everything will be attracted to.
			addObject(qb2Stock.newRectBody(new amPoint2d(100, 100), 100, 100, 100));
			
			//--- Add a bunch of lighter circles that get sucked in.
			var circleRadius:Number = 15;
			for (var i:int = 0; i < 50; i++) 
			{
				addObject(qb2Stock.newCircleShape(new amPoint2d(Math.random() * stageWidth, Math.random() * stageHeight), circleRadius, 1));
			}
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
			}
			else
			{
				//--- Leave the world's gravity the way we found it.
				evt.ancestor.world.gravity.copy(saveGravity);
				evt.ancestor.world.gravityZ = 0;
			}
		}
		
	}

}