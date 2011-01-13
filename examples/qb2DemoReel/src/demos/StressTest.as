package demos 
{
	import As3Math.geo2d.amPoint2d;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.display.Sprite;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2PolygonShape;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * Stressing the engine.
	 * 
	 * @author Doug Koellmer
	 */
	public class StressTest extends Demo
	{
		private static var squareSize:Number = 25;
		
		public function StressTest() 
		{
			var pyramidBase:int = 18;
			
			var center:amPoint2d = new amPoint2d(stage.stageWidth / 2, stage.stageHeight - (squareSize*pyramidBase)/2);
			var utilPoint:amPoint2d = new amPoint2d();
			for (var i:int = 0; i < pyramidBase; i++) 
			{
				var across:int = pyramidBase-i;
				for (var j:int = 0; j < across; j++) 
				{
					var x:Number = center.x - across * (squareSize / 2) + j * squareSize;
					var y:Number = center.y + pyramidBase * (squareSize / 2)  - i * squareSize;
					addObject(makeRedSquare(utilPoint.set(x, y))); 
				}
				
			}
		}
		
		private static function makeRedSquare(position:amPoint2d):qb2Body
		{
			var body:qb2Body = new qb2Body();
			var img:Bitmap = new Bitmap(new BitmapData(1, 1, false, 0xff0000), PixelSnapping.NEVER);
			img.width = img.height = squareSize;
			img.x -= squareSize / 2;
			img.y -= squareSize / 2;
			var rect:qb2PolygonShape = qb2Stock.newRectShape(new amPoint2d(), squareSize, squareSize);
			rect.actor = img;
			body.actor = new Sprite();
			body.addObject(rect); // adds the actor too.
			body.mass = 1;
			body.position.copy(position);
			body.drawsDebug = false;
			
			return body;
		}
	}
}