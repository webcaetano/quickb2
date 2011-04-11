package demos 
{
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import flash.utils.getTimer;
	import QuickB2.events.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	
	/**
	 * With QuickB2 it's easy to change transformations any time you want, without having to destroy/remake anything.
	 * 
	 * @author Doug Koellmer
	 */
	public class ShapeTransformation extends Demo
	{
		private var aBody:qb2Body = new qb2Body();
		
		public function ShapeTransformation() 
		{
			var radius:Number = 50;
			var size:Number = 40;
			
			aBody.addObject(qb2Stock.newRectShape(new amPoint2d(0, -radius), size * 1.5, size, 1));
			aBody.addObject(qb2Stock.newCircleShape(new amPoint2d(radius, 0), size * .75, 1));
			aBody.addObject(qb2Stock.newRectShape(new amPoint2d(0,  radius), size * 1.5, size, 1));
			aBody.addObject(qb2Stock.newCircleShape(new amPoint2d( -radius, 0), size * .75, 1));
			aBody.addObject(qb2Stock.newLineBody(new amPoint2d(-radius*2), new amPoint2d(radius*2, 0), 10, 1, qb2Stock.ENDS_ROUND));
			
			aBody.position.set(stage.stageWidth / 2, stage.stageHeight / 2);
			this.addObject(aBody);
			
			aBody.addEventListener(qb2UpdateEvent.POST_UPDATE, updateShapes);
		}
		
		private function updateShapes(evt:qb2UpdateEvent):void
		{
			//--- Rotate all the body's children around the body's local center.
			//--- Edit session is optional, but should result in a minor speed boost.
			aBody.pushEditSession();
			{
				var direction:Number = -1;
				for (var i:int = 0; i < aBody.numObjects; i++) 
				{
					var rigid:qb2IRigidObject = aBody.getObjectAt(i) as qb2IRigidObject;
					
					rigid.position.rotateBy(RAD_1 * direction, new amPoint2d());
					
					if ( rigid is qb2CircleShape )  continue;
					
					//--- Make different things rotate at different speeds.
					var mult:Number = rigid is qb2Body ? 4 : -6;
					rigid.rotateBy(-RAD_1 * direction * mult, rigid.position);
					
					direction = -direction;
				}
			}
			aBody.popEditSession();
		}
	}
}