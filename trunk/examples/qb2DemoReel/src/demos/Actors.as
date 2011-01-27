package demos 
{
	import As3Math.geo2d.amPoint2d;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.stock.qb2Stock;
	
	/**
	 * Simple demo showing how to attach actors to your physics bodies.
	 * 
	 * @author Doug Koellmer
	 */
	public class Actors extends Demo
	{
		[Embed(source = '../../lib/doug_koellmer.jpg')]
		private static const PicOfMe:Class;
		
		public function Actors() 
		{
			var numPics:uint = 10;
			var center:amPoint2d = new amPoint2d(stage.stageWidth / 2, stage.stageHeight / 2);
			
			for (var i:int = 0; i < numPics; i++) 
			{
				var pic:qb2Body = makePic();
				
				//--- Move pic to center.  Note that it's top-left oriented, so has to be adjusted a bit.
				pic.position.copy(center);
				pic.position.x -= pic.getBoundBox().width / 2;
				pic.position.y -= pic.getBoundBox().height / 2;
				
				addObject(pic);
			}
			
			this.joinsInDebugDrawing = false;
		}
		
		private static function makePic():qb2Body
		{
			var body:qb2Body = new qb2Body();
			var img:Bitmap = (new PicOfMe()) as Bitmap;
			img.smoothing = true;
			body.actor = img;
			body.addObject(qb2Stock.newRectShape(new amPoint2d(img.width / 2, img.height / 2), img.width, img.height));
			body.mass = 1;
			return body;
		}
	}
}