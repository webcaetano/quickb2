package QuickB2.internals 
{
	import As3Math.geo2d.amLine2d;
	import As3Math.geo2d.amPoint2d;
	import As3Math.geo2d.amPolygon2d;
	import As3Math.geo2d.amVector2d;
	import Box2DAS.Common.V2;
	import Box2DAS.Dynamics.b2DestructionListener;
	import Box2DAS.Dynamics.b2Filter;
	import Box2DAS.Dynamics.b2Fixture;
	import Box2DAS.Dynamics.Joints.b2PrismaticJoint;
	import flash.utils.Dictionary;
	import QuickB2.debugging.qb2_debugDrawFlags;
	import QuickB2.misc.qb2_flags;
	import QuickB2.misc.qb2_props;
	import QuickB2.misc.qb2TreeTraverser;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2CircleShape;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
	import QuickB2.objects.tangibles.qb2PolygonShape;
	import QuickB2.objects.tangibles.qb2Shape;
	import QuickB2.objects.tangibles.qb2Tangible;
	import QuickB2.qb2_errors;
	import QuickB2.qb2_friend;
	import QuickB2.stock.qb2Stock;
	use namespace qb2_friend;

	/**
	 * The "slice" implementation is put here so that qb2Tangible::slice() doesn't add another few hundred lines of code to an already too-long file.
	 * @author Doug Koellmer
	 * @private
	 */
	public class qb2InternalSliceUtility 
	{
		private static var traverser:qb2TreeTraverser;
		
		private static var shapeDict:Dictionary;
		private static var rootTang:qb2Tangible;
		private static var sliceLine:amLine2d = null;
		private static var outputArrayOfPoints:Vector.<amPoint2d> = null;
		
		private static var begRay:amLine2d = new amLine2d();
		private static var endRay:amLine2d = new amLine2d();
		
		private static var MIN_VALUE:Number = Number.MIN_VALUE+2;
		private static var MAX_VALUE:Number = Number.MAX_VALUE-2;
		
		private static const borders:Vector.<amLine2d> = Vector.<amLine2d>
		([
			new amLine2d(new amPoint2d(MIN_VALUE, MAX_VALUE), new amPoint2d(MIN_VALUE, MIN_VALUE)),
			new amLine2d(new amPoint2d(MIN_VALUE, MIN_VALUE), new amPoint2d(MAX_VALUE, MIN_VALUE)),
			new amLine2d(new amPoint2d(MAX_VALUE, MIN_VALUE), new amPoint2d(MAX_VALUE, MAX_VALUE)),
			new amLine2d(new amPoint2d(MAX_VALUE, MAX_VALUE), new amPoint2d(MIN_VALUE, MAX_VALUE))
		]);
		
		qb2_friend static function slice(tang:qb2Tangible, line:amLine2d, outputPoints:Vector.<amPoint2d>, includePartials:Boolean):Vector.<qb2Tangible>
		{
			if ( !tang.world )
			{
				throw qb2_errors.NOT_IN_WORLD;
			}
			
			rootTang = tang;
			sliceLine = line;
			outputArrayOfPoints = outputPoints;
		
			begRay.copy(line);
			begRay.flip();
			begRay.lineType = amLine2d.LINE_TYPE_RAY;
			endRay.copy(line);
			endRay.lineType = amLine2d.LINE_TYPE_RAY;
			var modBeg:V2 = null;
			var modEnd:V2 = null;
			var intPoint:amPoint2d = new amPoint2d();
			var pixPer:Number = tang.worldPixelsPerMeter;
			for (var j:int = 0; j < borders.length; j++) 
			{
				if ( !modBeg )
				{
					if( begRay.intersectsLine(borders[j], intPoint) )
					{
						modBeg = new V2(intPoint.x / pixPer, intPoint.y / pixPer);
					}
				}
				
				if ( !modEnd )
				{
					if( endRay.intersectsLine(borders[j], intPoint) )
					{
						modEnd = new V2(intPoint.x / pixPer, intPoint.y / pixPer);
					}
				}
				
				if ( modBeg && modEnd )
				{
					break;
				}
			}
			
			shapeDict = null;
			tang.world.b2_world.RayCast(raycastCallback, modBeg, modEnd);
			
			//--- Ray didn't hit anything on this tangible.
			if ( !shapeDict )
			{
				return null;
			}
			
			var toReturn:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
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
					
					if ( currObject is qb2Shape )
					{
						if ( shapeDict[currObject] )
						{
							var poly:qb2PolygonShape = null;
							
							if ( currObject is qb2CircleShape )
							{
								
							}
							else
							{
								poly = asShape as qb2PolygonShape;
							}
							
							
						}
					}

					traverser.next(true);
				}
			}
			else
			{
				var asShape:qb2Shape = tang as qb2Shape;
				for (var i:int = 0; i < asShape.fixtures.length; i++) 
				{
					var ithFixture:b2Fixture = asShape.fixtures[i];
					
				}
			}
			
			shapeDict = null;
			
			return toReturn;
		}
		
		private static var utilPoint:amPoint2d = new amPoint2d();
		private static var utilLine:amLine2d = new amLine2d();
		private static var HIT_TOLERANCE:Number = .0001;
		
		private static function raycastCallback(fixture:b2Fixture, point:V2, normal:V2, fraction:Number):Number
		{
			var toReturn:Number = 1;
			
			var shape:qb2Shape = fixture.m_userData as qb2Shape;
			
			//--- Continue on if the root tangible is a shape and not this shape that just got hit.
			if ( (rootTang is qb2Shape) && shape != rootTang )
			{
				return toReturn;
			}
			
			//--- Find out if this object is sliceable, or even a part of the rootTang hierarchy.
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
			
			//--- Continue if this shape is not sliceable or not part of the rootTang hierarchy.
			if ( !isSliceable )
			{
				return toReturn;
			}
			
			//--- Continue if the hitpoint isn't on the slice line.
			var pixPerMeter:Number = shape.worldPixelsPerMeter;
			utilPoint.set(point.x * pixPerMeter, point.y * pixPerMeter);
			if ( !sliceLine.isOn(utilPoint, HIT_TOLERANCE) )
			{
				return toReturn;
			}
			
			//--- Continue if the hitpoint is inside a polygon (it has hit the internal border between two polygons forming the decomposition of a non-convex polygon).
			if ( shape is qb2PolygonShape )
			{
				//--- Only non-convex polygons have a chance for an "internal hit", because they're decomposed to several convex polygons.
				var foundOnBorder:Boolean = false;
				var asPolygon:qb2PolygonShape = shape as qb2PolygonShape;
				if ( !asPolygon.polygon.convex )
				{
					var polygon:amPolygon2d = asPolygon.polygon;
					for (var i:int = 1; i < polygon.numVertices; i++) 
					{
						utilLine.set(polygon.getVertexAt(i - 1), polygon.getVertexAt(i));
						if ( utilLine.isOn(utilPoint, HIT_TOLERANCE) )
						{
							foundOnBorder = true;
							break;
						}
					}
					
					if ( !foundOnBorder )
					{
						return toReturn;
					}
				}
			}
			
			//--- Add the point to the list of output points.
			var outputPoint:amPoint2d = utilPoint.clone();
			if ( outputArrayOfPoints )
			{
				outputArrayOfPoints.push(outputPoint);
			}
			
			//--- Create a dictionary for this shape that is an array of points, if it's not made already.
			shapeDict = shapeDict ? shapeDict : new Dictionary(true);
			shapeDict[shape] = shapeDict[shape] ? shapeDict[shape] : [];
			shapeDict[shape].push(outputPoint);
			
			return toReturn;
		}
	}
}