package QuickB2.misc.acting 
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import QuickB2.loaders.proxies.qb2Proxy;
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2_flashActorUtils
	{
		public static function scaleActor(actor:DisplayObject, xValue:Number, yValue:Number):void
		{
			var mat:Matrix = actor.transform.matrix;
			mat.scale(xValue, yValue);
			actor.transform.matrix = mat;
		}
		
		public static function cloneSprite(sprite:Sprite):Sprite
		{
			var actorClone:Sprite = new (Object(sprite).constructor as Class) as Sprite;
			actorClone.transform.matrix = sprite.transform.matrix.clone();
			
			//--- An actor can only contain proxies that should be deleted if
			//--- it itself is a proxy, so this check can save some search time.
			if ( actorClone is qb2Proxy )
			{
				var container:DisplayObjectContainer = actorClone as DisplayObjectContainer;
				var numChildren:int = container.numChildren;
				for (var i:int = 0; i < numChildren; i++) 
				{
					if ( container.getChildAt(i) is qb2Proxy )
					{
						container.removeChildAt(i--);
					}
				}
			}
			
			return actorClone;
		}
	}
}