package demos 
{
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import QuickB2.events.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	
	/**
	 * This demo displays how objects can be removed from within a contact callback.
	 * 
	 * @author Doug Koellmer
	 */
	public class BubblePop extends Demo
	{
		public function BubblePop() 
		{
			this.restitution = .75;  // make this whole group pretty bouncy.
			
			var numAcross:uint = 10;
			var numDown:uint   = 6;
			var radius:Number = 20;
			
			var startX:Number = -numAcross * radius;
			var startY:Number = -numDown * radius;
			var start:amPoint2d = new amPoint2d(startX, startY);
			
			var bubbleBody:qb2Body = new qb2Body();
			bubbleBody.position.set(stageWidth/2, stageHeight/2);
			
			for (var i:int = 0; i < numAcross; i++) 
			{
				start.y = startY;
				for (var j:int = 0; j < numDown; j++) 
				{
					bubbleBody.addObject(qb2Stock.newCircleShape(new amPoint2d(start.x, start.y), radius, 1));
					start.y += radius * 2;
				}
				start.x += radius * 2;
			}
			bubbleBody.rotateBy(RAD_45, bubbleBody.position);
			addObject(bubbleBody);
			
			bubbleBody.addEventListener(qb2ContactEvent.CONTACT_STARTED, contactStarted);
		}
		
		private function contactStarted(evt:qb2ContactEvent):void
		{
			evt.localShape.removeFromParent(); // slowly chop away at the object.
		}
	}
}