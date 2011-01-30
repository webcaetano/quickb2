package QuickB2.internals 
{
	import As3Math.geo2d.amLine2d;
	import As3Math.geo2d.amVector2d;
	import Box2DAS.Common.V2;
	import Box2DAS.Dynamics.b2Fixture;
	import flash.utils.Dictionary;
	import QuickB2.debugging.qb2_debugDrawFlags;
	import QuickB2.misc.qb2_flags;
	import QuickB2.misc.qb2_props;
	import QuickB2.misc.qb2TreeTraverser;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
	import QuickB2.objects.tangibles.qb2Shape;
	import QuickB2.objects.tangibles.qb2Tangible;
	import QuickB2.qb2_errors;
	import QuickB2.qb2_friend;
	import QuickB2.stock.qb2Stock;
	use namespace qb2_friend;

	public class qb2InternalSliceUtility 
	{
		private static var traverser:qb2TreeTraverser;
		
		private static var fixtureDict:Dictionary;
		private static var shapeDict:Dictionary;
		private static var rootTang:qb2Tangible;
		
		qb2_friend static function slice(tang:qb2Tangible, line:amLine2d, includePartials:Boolean):qb2Tangible
		{
			if ( !tang.world )
			{
				throw qb2_errors.NOT_IN_WORLD;
			}
			
			rootTang = tang;
			var modifiedPoint1:V2 = null;
			var modifiedPoint2:V2 = null;
			tang.world.b2_world.RayCast(raycastCallback, modifiedPoint1, modifiedPoint2);
			
			
			if ( tang is qb2ObjectContainer )
			{
				var asContainer:qb2ObjectContainer = tang as qb2ObjectContainer;
				traverser = traverser ? traverser : new qb2TreeTraverser();
				traverser.root = asContainer;
				
				while ( traverser.hasNext() )
				{
					var currObject:qb2Object = traverser.currentObject;
					
					if( !currObject.isFlagOn(qb2_flags.T_IS_SLICEABLE) || !(currObject is qb2Tangible) )
					{
						traverser.next(false);
					}
					
					
					traverser.next(true);
				}
			}
			else
			{
				var asShape:qb2Shape = tang as qb2Shape;
				for (var i:int = 0; i < asShape.fixtures.length; i++) 
				{
					//var item: = [i];
					
				}
				//fixtureDict
			}
			
			return null;
		}
		
		private static function raycastCallback(fixture:b2Fixture, point:V2, normal:V2, fraction:Number):Number
		{
			var shape:qb2Shape = fixture.m_userData as qb2Shape;
			
			var isSliceable:Boolean = false;
			var currObject:qb2Object = shape;
			while ( currObject )
			{
				if ( !currObject.isFlagOn(qb2_flags.T_IS_SLICEABLE) )
				{
					break;
				}
				
				if ( currObject == rootTang )
				{
					isSliceable = true;
					break;
				}
				
				currObject = currObject.parent;
			}
			
			if ( !isSliceable )  return 0;
			
			if ( !fixtureDict )
			{
				fixtureDict = new Dictionary(true);
				shapeDict   = new Dictionary(true);
			}
			
			if ( !shapeDict[shape] )
			{
				shapeDict[shape] = true;
			}
			
			return 0;
		}
	}
}