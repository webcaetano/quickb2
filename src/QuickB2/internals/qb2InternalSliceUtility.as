package QuickB2.internals 
{
	import As3Math.consts.AM_PI;
	import As3Math.geo2d.*;
	import Box2DAS.Collision.b2AABB;
	import Box2DAS.Collision.Shapes.b2Shape;
	import Box2DAS.Common.*;
	import Box2DAS.Dynamics.*;
	import com.bit101.charts.LineChart;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	use namespace qb2_friend;

	/**
	 * The "slice" implementation is put here so that qb2Tangible::slice() doesn't add another gagillion lines of code to an already too-long file.
	 * @author Doug Koellmer
	 * @private
	 */
	public class qb2InternalSliceUtility 
	{
		private const traverser:qb2TreeTraverser = new qb2TreeTraverser();
		private const intPoints:Vector.<amPoint2d> = new Vector.<amPoint2d>();
		private const INFINITE:Number = 1000000;
		
		qb2_friend function slice(rootTang:qb2Tangible, sliceLine:amLine2d, outputPoints:Vector.<amPoint2d>, includePartialSlices:Boolean = true, keepOriginal:Boolean = false, addNewTangs:Boolean = true):Vector.<qb2Tangible>
		{
			var infiniteBeg:amPoint2d = sliceLine.point1.translatedBy(sliceLine.direction.negate().scaleBy(INFINITE));
			var distanceDict:Dictionary = new Dictionary(true); // stores point->point's distance from infiniteBeg
			var intDict:Dictionary = new Dictionary(true);  // stores point->point's intersection status, i.e. if it intersects an edge or a vertex.
			var toReturn:Vector.<qb2Tangible> = new Vector.<qb2Tangible>();
			traverser.root = rootTang;
			
			var numBegPointIntersections:int = 0;
			while ( traverser.hasNext )
			{
				var currObject:qb2Object = traverser.currentObject;
				
				//--- Proceed to the next object in the tree under a variety of conditions...
				if ( !(currObject is qb2Tangible) )
				{
					traverser.next(false);
					continue;
				}
				if( !currObject.isFlagOn(qb2_flags.T_IS_SLICEABLE) )
				{
					traverser.next(false);
					continue;
				}
				if ( !(currObject is qb2Shape) )
				{
					traverser.next(true);
					continue;
				}
				
				//--- Find intersection points with the slice line.
				intPoints.length = 0;
				utilArray.length = 0;
				var localSliceLine:amLine2d = currObject.parent ?
						new amLine2d(currObject.parent.getLocalPoint(sliceLine.point1, rootTang), currObject.parent.getLocalPoint(sliceLine.point2, rootTang), sliceLine.lineType) :
						new amLine2d(sliceLine.point1.clone(), sliceLine.point2.clone());
				var localSliceLineBeg:amPoint2d = localSliceLine.point1.translatedBy(localSliceLine.direction.negate().scaleBy(INFINITE));
				var localSliceLineInf:amLine2d = new amLine2d(localSliceLineBeg, localSliceLine.point2.clone(), localSliceLine.lineType);
				if ( currObject is qb2PolygonShape )
				{
					//--- Compare slice line against each polygon edge to determine intersection.
					var asPoly:qb2PolygonShape = currObject as qb2PolygonShape;
					var numVerts:int = asPoly.numVertices;
					for (var j:int = 0; j < numVerts; j++) 
					{
						var edgeBeg:amPoint2d = asPoly.getVertexAt(j);
						var edgeEnd:amPoint2d = asPoly.getVertexAt(j < numVerts-1 ? j+1 : 0);
						utilLine.set(edgeBeg, edgeEnd);
						
						if ( localSliceLineInf.intersectsLine(utilLine, utilPoint, INT_TOLERANCE) )
						{
							var newIntPoint:amPoint2d = utilPoint.clone();//
							utilArray.push(newIntPoint); 
							
							//--- Determine if the slice line goes through a vertex or the "meat" of an edge.
							if ( newIntPoint.distanceTo(edgeBeg) < DIST_TOLERANCE )
							{
								intDict[newIntPoint] = j * 2;
							}
							else
							{
								intDict[newIntPoint] = j * 2 + 1;
							}
						}
					}
				}
				else
				{
					var asCircle:qb2CircleShape = currObject as qb2CircleShape;
					var geoCircle:amCircle2d = asCircle.asCircle();
					localSliceLineInf.intersectsCircle(geoCircle, utilArray, INT_TOLERANCE);
					
					for (var m:int = 0; m < utilArray.length; m++) 
					{
						intDict[utilArray[m]] = -1;
					}
				}
				
				//--- Order the intersection points for this shape by their distance from the line's beginning.
				for (var k:int = 0; k < utilArray.length; k++) 
				{
					insertPointInOrder(utilArray[k], intPoints, distanceDict, localSliceLineBeg);
				}
				
				var numPreviousPointsOffSliceLine:int = 0;
				var encounteredPointOnSliceLine:Boolean = false;
				var ammendments:Array = [];
				for (var l:int = 0; l < intPoints.length; l++) 
				{
					var lthIntPoint:amPoint2d = intPoints[l];
					var numIntPoints:int = 0;
					
					//--- See if this int point is on the actual slice line (and not the infinite version), and then if it's an incoming or outgoing point.
					if ( localSliceLine.isOn(lthIntPoint, DIST_TOLERANCE) )
					{
						if ( numPreviousPointsOffSliceLine % 2 == 0 || encounteredPointOnSliceLine )
						{
							if ( l == intPoints.length - 1 )
							{
								numIntPoints = 1;
								lthIntPoint.userData = INCOMING;
							}
							else
							{
								numIntPoints = 2;
								lthIntPoint.userData    = INCOMING;
								intPoints[++l].userData = OUTGOING;
							}
						}
						else
						{
							numIntPoints = 1;
							lthIntPoint.userData = OUTGOING;
							numBegPointIntersections++;
						}
						
						encounteredPointOnSliceLine = true;
					}
					else
					{
						numPreviousPointsOffSliceLine++;
					}
					
					if ( numIntPoints == 1 && includePartialSlices ) // if this is a partial slice...
					{
						if ( outputPoints )
						{
							var outputPoint:amPoint2d = currObject.parent ? currObject.parent.getWorldPoint(lthIntPoint, rootTang.parent) : lthIntPoint;
							outputPoint.userData = lthIntPoint.userData;
							insertPointInOrder(outputPoint, outputPoints, distanceDict, infiniteBeg);
						}
						
						//--- Find the point that represents the penetration of this shape, either the beginning or end of the slice line in the shape's parent's coordinate space.
						var penetrationPoint:amPoint2d = null;
						if ( lthIntPoint.userData == OUTGOING )
						{
							penetrationPoint = currObject.parent ? currObject.parent.getLocalPoint(sliceLine.point1, rootTang.parent) : sliceLine.point1;
						}
						else
						{
							penetrationPoint = currObject.parent ? currObject.parent.getLocalPoint(sliceLine.point2, rootTang.parent) : sliceLine.point2;
						}
						
						//--- Get a polygon representation, either by casting or by converting a circle to a polygon based on where the slice line hit the circle.
						var polyShape:qb2PolygonShape = null;
						if ( currObject is qb2CircleShape )
						{
							polyShape = (currObject as qb2CircleShape).convertToPoly(false, true, -1, lthIntPoint);
						}
						else
						{
							polyShape = currObject as qb2PolygonShape;
						}
						
						var index:int = intDict[lthIntPoint];
						if ( index < 0 || index % 2 == 0 ) // sliceLine intersected a polygon's vertex, or a circle's boundary...either case is the same because the circle is decomposed to a polygon with vertices lining up to the slice line.
						{
							var cornerIndex:int = index < 0 ? 0 : index/2;
							var afterIndex:int  = cornerIndex == polyShape.numVertices - 1 ? 0 : cornerIndex + 1;
							var pinch:amPoint2d = polyShape.getVertexAt(cornerIndex).clone();
							
							if ( currObject is qb2PolygonShape )
							{
								adjustIntPoints(intPoints, l + 1, intDict, 2, afterIndex);
							}
							
							polyShape.insertVertexAt(afterIndex, penetrationPoint, pinch);
						}
						else // slice line intersected an edge of a polygon...
						{
							var edgeIndex:int = (index - 1) / 2;
							
							adjustIntPoints(intPoints, l + 1, intDict, 3, edgeIndex + 1);
							
							polyShape.insertVertexAt(edgeIndex + 1, lthIntPoint.clone(), penetrationPoint, lthIntPoint.clone());
						}
					}
					else if( numIntPoints == 2 ) // this is a slice that goes all the way through a discrete portion of the shape
					{
						var localIntPoint1:amPoint2d = lthIntPoint;
						var localIntPoint2:amPoint2d = intPoints[l];
						
						//--- Add the intersection points in order to the coordinate space of the original slice line if user wants output.
						if ( outputPoints )
						{
							var outputPoint1:amPoint2d = currObject.parent ? currObject.parent.getWorldPoint(localIntPoint1, rootTang.parent) : localIntPoint1;
							var outputPoint2:amPoint2d = currObject.parent ? currObject.parent.getWorldPoint(localIntPoint2, rootTang.parent) : localIntPoint2;
							outputPoint1.userData = localIntPoint1.userData;
							outputPoint2.userData = localIntPoint2.userData;
							insertPointInOrder(outputPoint1, outputPoints, distanceDict, infiniteBeg);
							insertPointInOrder(outputPoint2, outputPoints, distanceDict, infiniteBeg);
						}
						
						if ( currObject is qb2CircleShape ) // circle is an easy case...
						{
							asCircle = currObject as qb2CircleShape;
							
							var vec1:amVector2d = localIntPoint1.minus(asCircle.position);
							var vec2:amVector2d = localIntPoint2.minus(asCircle.position);
							var vec1ToVec2:Number = vec1.clockwiseAngleTo(vec2);
							var vec2ToVec1:Number = (AM_PI * 2) - vec1ToVec2;
							
							var poly1:qb2PolygonShape = polygonizeArc(asCircle, localIntPoint1, vec1ToVec2);
							var poly2:qb2PolygonShape = polygonizeArc(asCircle, localIntPoint2, vec2ToVec1);
							
							toReturn.push(poly1, poly2);
						}
						else if ( currObject is qb2PolygonShape )
						{
							asPoly = currObject as qb2PolygonShape;
							
							var index1:int = intDict[localIntPoint1];
							var index2:int = intDict[localIntPoint2];
							
							var newPoly:qb2PolygonShape = new qb2PolygonShape();
							newPoly.copyTangibleProps(asPoly);
							newPoly.copyPropertiesAndFlags(asPoly);
							toReturn.push(newPoly);
							
							var modIndex1:int = index1 % 2 == 0 ? index1 / 2 : (index1 - 1) / 2;
							var modIndex2:int = index2 % 2 == 0 ? index2 / 2 : (index2 - 1) / 2;
							/*if ( modIndex1 > modIndex2 )
							{
								var temp:int = modIndex1;
								modIndex1 = modIndex2;
								modIndex2 = temp;
								
								var tempPoint:amPoint2d = localIntPoint1;
								localIntPoint1 = localIntPoint2;
								localIntPoint2 = tempPoint;
							}*/
							var count:int = 0;
							
							var offset:int = 0;
							if ( index1 % 2 == 0 && index2 % 2 == 0 )
							{
								newPoly.addVertex(asPoly.getVertexAt(modIndex1).clone());
								while ( count <= modIndex2 )
								{
									var useIndex:int = (modIndex1 + 1) % asPoly.numVertices;
									
									newPoly.addVertex(asPoly.getVertexAt(useIndex).clone());
									
									if ( count < modIndex2 )
									{
										asPoly.removeVertexAt(useIndex);
										offset--;
									}
									
									count++;
								}
							}
							else if ( index1 % 2 == 0 )
							{
								newPoly.addVertex(asPoly.getVertexAt(modIndex1).clone());
								while ( count <= modIndex2 )
								{
									useIndex = (modIndex1 + 1) % asPoly.numVertices;
									
									newPoly.addVertex(asPoly.getVertexAt(useIndex).clone());
									
									asPoly.removeVertexAt(useIndex);
									offset--;
									
									count++;
								}
								
								newPoly.addVertex(localIntPoint2.clone());
								asPoly.insertVertexAt(modIndex1 + 1, localIntPoint2.clone());
								offset++;
							}
							else if ( index2 % 2 == 0 )
							{
								newPoly.addVertex(localIntPoint1.clone());
								asPoly.insertVertexAt(modIndex1 + 1, localIntPoint1.clone());
								offset++;
								
								while ( count <= modIndex2 )
								{
									useIndex = (modIndex1 + 1) % asPoly.numVertices;
									
									newPoly.addVertex(asPoly.getVertexAt(useIndex).clone());
									
									if ( count < modIndex2 )
									{
										asPoly.removeVertexAt(useIndex);
										offset--;
									}
									
									count++;
								}
							}
							else
							{
								newPoly.addVertex(localIntPoint1.clone());
								asPoly.insertVertexAt(modIndex1, localIntPoint1.clone());
								adjustIntPoints(intPoints, l + 1, intDict, 1, modIndex1);
								
								var numOfOperations:int = 0;
								
								while ( count % asPoly.numVertices <= modIndex2 )
								{
									useIndex = (modIndex1 + 2) % asPoly.numVertices;
									
									newPoly.addVertex(asPoly.getVertexAt(useIndex).clone());
									
									asPoly.removeVertexAt(useIndex);
									offset--;
									
									count++;
								}
								
								newPoly.addVertex(localIntPoint2.clone());
								asPoly.insertVertexAt(modIndex1 + 2 % asPoly.numVertices, localIntPoint2.clone());
								offset++;
							}
							
							adjustIntPoints(intPoints, l + 1, intDict, offset, modIndex1);
							
							if ( asPoly.parent )
							{
								newPoly.position = asPoly.parent.getWorldPoint(newPoly.position, rootTang);
								rootTang.parent.addObject(newPoly);
							}
						}
					}
				}
				
				traverser.next();
			}
			
			//--- Add caps to the intersection points for the beg/end of the slice line, if needed.
			if ( outputPoints )
			{
				if ( sliceLine.lineType != amLine2d.LINE_TYPE_INFINITE )
				{
					var lineBeg:amPoint2d = sliceLine.point1.clone();
					lineBeg.userData = numBegPointIntersections;
					outputPoints.unshift(lineBeg);
				}
				
				if ( sliceLine.lineType == amLine2d.LINE_TYPE_SEGMENT )
				{
					outputPoints.push(sliceLine.point2.clone());
				}
			}
			
			return toReturn;
		}
		
		private function adjustIntPoints(intPoints:Vector.<amPoint2d>, startIndex:int, intDict:Dictionary, offset:int, vertexIndex:int):void
		{
			for (var i:int = startIndex; i < intPoints.length; i++) 
			{
				var ithIntPoint:amPoint2d = intPoints[i];
				
				var baseIndex:int = intDict[ithIntPoint];
				
				if ( baseIndex % 2 == 0 )
				{
					var actualIndex:int = baseIndex / 2;
					
					if ( actualIndex >= vertexIndex )
					{
						actualIndex += offset;
						intDict[ithIntPoint] = actualIndex * 2;
					}
				}
				else
				{
					actualIndex = (baseIndex - 1) / 2;
					
					if ( actualIndex >= vertexIndex )
					{
						actualIndex += offset;
						intDict[ithIntPoint] = actualIndex * 2 + 1;
					}
				}
			}
		}
		
		private function polygonizeArc(circleShape:qb2CircleShape, startPoint:amPoint2d, sweepAngle:Number):qb2PolygonShape
		{
			var circum:Number = circleShape.perimeter;
			var ratio:Number = sweepAngle / (AM_PI * 2);
			var arcLength:Number = ratio * circum;
			
			const min:int = 2;
			var approx:Number = circleShape.arcApproximation;
			var numSegs:int = Math.max(arcLength / approx, min);
			var angInc:Number = (AM_PI * 2) * ((arcLength / (numSegs as Number)) / circum);
			
			var poly:qb2PolygonShape = new qb2PolygonShape();
			poly.addVertex(startPoint.clone() );
			var rotPoint:amPoint2d = startPoint.clone();
			for (var i:int = 0; i < numSegs; i++) 
			{
				poly.addVertex(rotPoint.rotateBy(angInc, circleShape.position).clone());
			}
			
			poly.copyTangibleProps(circleShape);
			poly.copyPropertiesAndFlags(circleShape);
			
			if ( circleShape.parent )
			{
				poly.position = circleShape.parent.getWorldPoint(poly.position, traverser.root as qb2Tangible);
				traverser.root.parent.addObject(poly);
			}
			
			return poly;
		}
		
		/*private function insertAmmendment(object:*, index:int, currentAmmendments:Array):void
		{
			if ( object is amPoint2d )
			{
				(object as amPoint2d).userData = index;
			}
			
			var inserted:Boolean = false;
			for (var i:int = 0; i < currentAmmendments.length; i++) 
			{
				if( (currentAmmendments[i] is int) && (currentAmmendments[i] as int) < 
			}
			
			if ( !inserted )
			{
				currentAmmendments.push(object);
			}
		}*/
		
		private function insertPointInOrder(point:amPoint2d, otherPoints:Vector.<amPoint2d>, distanceDict:Dictionary, basePoint:amPoint2d):amPoint2d
		{
			var distance:Number = 0;
			if ( !distanceDict[point] )
			{
				distance = point.distanceTo(basePoint);
				distanceDict[point] = distance;
			}
			else
			{
				distance = distanceDict[point] as Number;
			}
			
			var inserted:Boolean = false;
			for (var i:int = 0; i < otherPoints.length; i++) 
			{
				if ( distance < distanceDict[otherPoints[i]] )
				{
					otherPoints.splice(i, 0, point);
					inserted = true;
					break;
				}
			}
			
			if ( !inserted )
			{
				otherPoints.push(point);
			}
			
			return point;
		}
		
		/*private function addLineCaps():void
		{
			
		}*/
		
		private var utilPoint:amPoint2d = new amPoint2d();
		private var utilLine:amLine2d = new amLine2d();
		private var utilArray:Vector.<amPoint2d> = new Vector.<amPoint2d>();
		
		private const INCOMING:String = "incoming";
		private const OUTGOING:String = "outgoing";
		private const INT_TOLERANCE:Number = .00000001;
		private const DIST_TOLERANCE:Number = .001;
	}
}