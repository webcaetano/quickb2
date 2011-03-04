package demos 
{
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import QuickB2.effects.qb2GravityField;
	import QuickB2.effects.qb2GravityWellField;
	import QuickB2.effects.qb2PlanetaryGravityField;
	import QuickB2.effects.qb2VibratorField;
	import QuickB2.effects.qb2WindField;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.misc.qb2Keyboard;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
	import QuickB2.objects.tangibles.qb2PolygonShape;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * Some of the various effect fields available.
	 * 
	 * @author Doug Koellmer
	 */
	public class EffectFields extends Demo
	{
		public function EffectFields() 
		{
			var numCircles:int = 50;
			var circleRadius:Number = 15;
			var seperation:Number = circleRadius;
			var fieldWidth:Number = stageWidth / 2 - seperation;
			var fieldHeight:Number = stageHeight / 2 - seperation;
			
			//--- A gravity field applies linear gravity in a certain direction.
			var gravField:qb2GravityField = new qb2GravityField();
			gravField.position.set(stageWidth / 4, stageHeight / 4);
			gravField.addObject(qb2Stock.newRectBody(new amPoint2d(), fieldWidth, fieldHeight));
			gravField.vector.y = -10;
			
			//--- Edit the field's geometry a bit to make it into a bow tie shape.
			//--- All the other fields will use a clone of this geometry as well.
			var poly:qb2PolygonShape = (gravField.lastObject() as qb2Body).lastObject() as qb2PolygonShape;
			poly.insertVertexAt(1, new amPoint2d(0, -fieldHeight / 2 + circleRadius));
			poly.insertVertexAt(4, new amPoint2d(0, fieldHeight / 2 - circleRadius));
			addObject(gravField);
			
			//--- A gravity well field can be used to make a black hole or something in your game.
			var wellField:qb2GravityWellField = new qb2GravityWellField();
			wellField.position.set(stageWidth * .75, stageHeight / 4);
			wellField.addObject(gravField.lastObject().clone()); // the power of cloning :)
			addObject(wellField);
			
			//--- A vibrator field uses impulses to shake stuff around.
			var vibratorField:qb2VibratorField = new qb2VibratorField();
			vibratorField.position.set(stageWidth * .75, stageHeight * .75);
			vibratorField.addObject(gravField.lastObject().clone());
			
			//--- A wind field uses forces to blow stuff around.
			var windField:qb2WindField = new qb2WindField();
			windField.position.set(stageWidth / 4, stageHeight * .75);
			windField.addObject(gravField.lastObject().clone());
			windField.vector.set( -5, 0);
			windField.airDensity = 2;
			
			//--- Another linear gravity field, but notice how the vibrator and wind fields are added to this field.
			//--- This effectively stacks the fields, conveniently giving the vibrator/wind fields gravity also.
			var anotherGravField:qb2GravityField = new qb2GravityField();
			anotherGravField.vector.y = 10;
			anotherGravField.addObject(vibratorField);
			anotherGravField.addObject(windField);
			addObject(anotherGravField);
			
			//--- Add a bunch of circles to see the effects.
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