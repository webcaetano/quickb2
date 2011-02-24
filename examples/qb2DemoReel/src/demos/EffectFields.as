package demos 
{
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amVector2d;
	import QuickB2.effects.qb2GravityField;
	import QuickB2.effects.qb2VibratorField;
	import QuickB2.misc.qb2Keyboard;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
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
			var seperation:Number = 0;// circleRadius * 5;
			var fieldWidth:Number = stageWidth / 2 - seperation;
			var fieldHeight:Number = stageHeight / 2 - seperation;
			
			//--- A gravity field applies linear gravity in a certain direction.
			var gravField:qb2GravityField = new qb2GravityField();
			gravField.position.set(stageWidth / 4, stageHeight / 4);
			gravField.addObject(qb2Stock.newRoundedRectBody(new amPoint2d(), fieldWidth, fieldHeight, circleRadius*4));
			gravField.gravityVector.y = - 20; // enough to counteract default world gravity and reverse it, basically.
			addObject(gravField);
			
			//--- A vibrator field uses impulses to shake stuff around.
			var vibratorField:qb2VibratorField = new qb2VibratorField();
			vibratorField.position.set(stageWidth * .75, stageHeight * .75);
			vibratorField.addObject(gravField.lastObject().clone()); // the power of cloning :)
			addObject(vibratorField);
			
			//--- Add a bunch of circles to see the effects.
			for (var i:int = 0; i < 1; i++) 
			{
				addObject(qb2Stock.newCircleShape(new amPoint2d(Math.random() * stageWidth, Math.random() * stageHeight), circleRadius, 1));
			}
			
			var roundRect:qb2Body = qb2Stock.newRoundedRectBody(new amPoint2d(100, 100), 100, 50, 10, 1);
			roundRect.removeObjectAt(0);
			roundRect.removeObjectAt(0);
			roundRect.removeObjectAt(0);
			addObject(roundRect);
		}
	}
}