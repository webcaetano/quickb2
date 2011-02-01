package QuickB2.internals 
{
	import As3Math.geo2d.*;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
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
		private static var pointDict:Dictionary;
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
		
		qb2_friend static function slice(tang:qb2Tangible, line:amLine2d, outputPoints:Vector.<amPoint2d>, includePartialSlices:Boolean = true, keepOriginal:Boolean = false, addNewTangs:Boolean = true):Vector.<qb2Tangible>
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
			pointDict = null;
			tang.world.b2_world.RayCast(raycastCallback, modBeg, modEnd);
			
			//--- Ray didn't hit anything on this tangible.
			if ( !shapeDict )
			{
				return null;
			}
			
			var toReturn:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			
			var asContainer:qb2ObjectContainer = tang as qb2ObjectContainer;
			traverser = traverser ? traverser : new qb2TreeTraverser();
			traverser.root = asContainer;
			
			while ( traverser.hasNext )
			{
				var currObject:qb2Object = traverser.currentObject;
				
				if( !currObject.isFlagOn(qb2_flags.T_IS_SLICEABLE) || !(currObject is qb2Tangible) )
				{
					traverser.next(false);
				}
				
				if ( currObject is qb2Shape )
				{
					if ( !shapeDict[currObject] )
					{
						traverser.next(true);
					}
					
					var intPoints:Vector.<amPoint2d> = shapeDict[currObject] as Vector.<amPoint2d>;
					
					if ( intPoints.length == 1 )
					{
						if ( !includePartialSlices )
						{
							traverser.next(true);
						}
						//else (search for tangents (raycasts that just hit the edge of the boundary)
						//{
						//	traverser.next(true);
						//}
					}
					
					var localIntPoint:amPoint2d;
					
					if ( currObject is qb2CircleShape )
					{
						var asCircle:qb2CircleShape = currObject as qb2CircleShape;
						
						if ( intPoints.length == 1 )
						{
							localIntPoint = asCircle.parent.getLocalPoint(intPoints[0]);
							
							var penetrationPoint:amPoint2d = null;
							if ( line.lineType == amLine2d.LINE_TYPE_RAY )
							{
								penetrationPoint = asCircle.parent.getLocalPoint(line.point1);
							}
							else
							{
								
							}
							
							
							
							var polyApprox:qb2PolygonShape = asCircle.convertToPoly(false, false, -1, localIntPoint);
							//polyApprox.insertVertexAt(
						}
					}
					else
					{
						var asPoly:qb2PolygonShape = currObject as qb2PolygonShape;
						
					}
				}
				else
				{
					traverser.next(true);
				}
			}
			
			shapeDict = null;
			pointDict = null;
			
			return toReturn;
		}
		
		private static var utilPoint:amPoint2d = new amPoint2d();
		private static var utilLine:amLine2d = new amLine2d();
		private static var HIT_TOLERANCE:Number = .001;
		
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
			var outputPoint:amPoint2d = null;
			if ( shape is qb2PolygonShape )
			{
				//--- Only non-convex polygons have a chance for an "internal hit", because they're decomposed to several convex polygons.
				var foundOnBorder:Boolean = false;
				var asPolygon:qb2PolygonShape = shape as qb2PolygonShape;
				var polygon:amPolygon2d = asPolygon.polygon;
				for (var i:int = 1; i < polygon.numVertices; i++) 
				{
					utilLine.set(polygon.getVertexAt(i - 1), polygon.getVertexAt(i));
					if ( utilLine.isOn(utilPoint, HIT_TOLERANCE) )
					{
						pointDict = pointDict ? pointDict : new Dictionary(true);
						outputPoint = utilPoint.clone();
						
						if ( utilLine.point1.equals(utilPoint, HIT_TOLERANCE) )
						{
							pointDict[outputPoint] = (i-1)*2 // even number signifies intersection of corner of polygon.
						}
						else if ( utilLine.point2.equals(utilPoint, HIT_TOLERANCE) )
						{
							pointDict[outputPoint] = i*2 // even number signifies intersection of corner of polygon.
						}
						else
						{
							pointDict[outputPoint] = (i - 1) * 2 - 1; // odd number signifies line intersection.
						}
						
						foundOnBorder = true;
						break;
					}
				}
				
				if ( !foundOnBorder )
				{
					return toReturn;
				}
			}
			else
			{
				pointDict = pointDict ? pointDict : new Dictionary(true);
				outputPoint = utilPoint.clone();
				pointDict[outputPoint] = -1; // negative number signifies intersection with a circle.
			}
			
			//--- Add the point to the list of output points.
			
			if ( outputArrayOfPoints )
			{
				outputArrayOfPoints.push(outputPoint);
			}
			
			//--- Create a dictionary for this shape that is an array of points, if it's not made already.
			shapeDict = shapeDict ? shapeDict : new Dictionary(true);
			shapeDict[shape] = shapeDict[shape] ? shapeDict[shape] : new Vector.<amPoint2d>;
			shapeDict[shape].push(outputPoint);
			
			return toReturn;
		}
	}
}