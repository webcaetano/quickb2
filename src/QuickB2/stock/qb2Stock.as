/**
 * Copyright (c) 2010 Johnson Center for Simulation at Pine Technical College
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package QuickB2.stock
{
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import flash.display.*;
	import QuickB2.*;
	import QuickB2.events.*;
	import QuickB2.misc.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	import surrender.srGraphics2d;

	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2Stock
	{
		public static const ENDS_SQUARE:uint = 1;
		public static const ENDS_ROUND:uint = 2;
		
		public static const CORNERS_SHARP:uint = 1;
		public static const CORNERS_ROUND:uint = 2;
		public static const CORNERS_NONE:uint = 3;
		
		public static function newCircleShape(center:amPoint2d, radius:Number, mass:Number = 0):qb2CircleShape
		{
			var circle:qb2CircleShape = new qb2CircleShape();
			circle.set(center, radius);
			if ( mass )  circle.mass = mass;
			
			return circle;
		}
		
		public static function newPolygonShape(vertices:Vector.<amPoint2d>, registrationPoint:amPoint2d = null, mass:Number = 0 ):qb2PolygonShape
		{
			var poly:qb2PolygonShape = new qb2PolygonShape();
			poly.set(vertices, registrationPoint, true);
			if ( mass )  poly.mass = mass;
			
			return poly;
		}
		
		public static function newRectShape(center:amPoint2d, width:Number, height:Number, mass:Number = 0, initRotation:Number = 0):qb2PolygonShape
		{
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>(4, true);
			verts[0] = new amPoint2d(center.x - width / 2, center.y - height / 2);
			verts[1] = new amPoint2d(center.x + width / 2, center.y - height / 2);
			verts[2] = new amPoint2d(center.x + width / 2, center.y + height / 2);
			verts[3] = new amPoint2d(center.x - width / 2, center.y + height / 2);
			
			var poly:qb2PolygonShape = new qb2PolygonShape();
			poly.set(verts, center);
			if ( mass )  poly.mass = mass;
			poly.rotation = initRotation;
			
			return poly;
		}
		
		public static function newEllipseShape(center:amPoint2d, majorAxis:amVector2d, minorAxisLength:Number, numSegs:uint, startAngle:Number = 0, endAngle:Number = 6.283185307179586, mass:Number = 0, solid:Boolean = true):qb2PolygonShape
		{
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>();
			
			var majorAxisLength:Number = majorAxis.length;
			
			var offsetAngle:Number = amVector2d.newVector(0, -1).signedAngleTo(majorAxis);
			
			var sinBeta:Number = Math.sin(offsetAngle - AM_PI / 2);
			var cosBeta:Number = Math.cos(offsetAngle - AM_PI / 2);
			
			var sweepAngle:Number = endAngle - startAngle;
			var closed:Boolean = sweepAngle  == AM_PI * 2;
			var inc:Number = sweepAngle / Number( closed ? numSegs : numSegs - 1);
			numSegs = closed && !solid ? numSegs + 1 : numSegs;
			
			for (var i:int = 0; i < numSegs; i++) 
			{
				var alpha:Number = i * inc;
				var sinAlpha:Number = Math.sin(alpha + startAngle);
				var cosAlpha:Number = Math.cos(alpha + startAngle);
				
				var x:Number = center.x + (majorAxisLength * cosAlpha * cosBeta - minorAxisLength * sinAlpha * sinBeta);
				var y:Number = center.y + (majorAxisLength * cosAlpha * sinBeta + minorAxisLength * sinAlpha * cosBeta);
				
				verts.push(new amPoint2d(x, y));
			}
			
			if ( solid && !closed )
			{
				verts.push(center.clone());
			}
			
			var poly:qb2PolygonShape = new qb2PolygonShape();
			poly.set(verts, center, solid);
			if ( mass )  poly.mass = mass;
			
			return poly;
		}
		
		public static function newRectBody(center:amPoint2d, width:Number, height:Number, mass:Number = 0, initRotation:Number = 0):qb2Body
		{
			var body:qb2Body = new qb2Body();
			body.setTransform(center, initRotation);
			body.addObject(newRectShape(new amPoint2d(), width, height, mass, 0));
			return body;
		}
		
		public static function newCircleBody(center:amPoint2d, radius:Number, mass:Number = 0):qb2Body
		{
			var body:qb2Body = new qb2Body();
			body.position = center;
			body.addObject(newCircleShape(new amPoint2d(), radius, mass));
			return body;
		}
		
		public static function newRectSensor(center:amPoint2d, width:Number, height:Number, initRotation:Number = 0, tripCallback:Function = null, tripTime:Number = 0):qb2TripSensor
		{
			var sensor:qb2TripSensor = new qb2TripSensor();
			sensor.setTransform(center, initRotation);
			sensor.addObject(newRectShape(new amPoint2d(), width, height));
			sensor.tripTime = tripTime;
			if ( tripCallback != null)  sensor.addEventListener(qb2TripSensorEvent.SENSOR_TRIPPED, tripCallback );
			return sensor;
		}
		
		public static function newCircleSensor(center:amPoint2d, radius:Number, tripTime:Number = 0, tripCallback:Function = null):qb2TripSensor
		{
			var sensor:qb2TripSensor = new qb2TripSensor();
			sensor.setTransform(center, 0);
			sensor.addObject(newCircleShape(new amPoint2d(), radius));
			sensor.tripTime = tripTime;
			if ( tripCallback != null )  sensor.addEventListener(qb2TripSensorEvent.SENSOR_TRIPPED, tripCallback );
			return sensor;
		}
		
		public static function newLineBody(beg:amPoint2d, end:amPoint2d, thickness:Number = 1, mass:Number = 0, ends:uint = ENDS_SQUARE):qb2Body
		{
			return newPolylineBody(Vector.<amPoint2d>([beg, end]), thickness, mass, CORNERS_NONE, ends, beg.midwayPoint(end));
		}
		
		public static function newEllipticalArcBody(center:amPoint2d, majorAxis:amVector2d, minorAxisLength:Number, numSegs:uint, startAngle:Number = 0, endAngle:Number = 6.283185307179586, thickness:Number = 1, mass:Number = 0, corners:uint = CORNERS_SHARP, ends:uint = ENDS_SQUARE):qb2Body
		{
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>();
			
			var majorAxisLength:Number = majorAxis.length;
			
			var offsetAngle:Number = amVector2d.newVector(0, -1).signedAngleTo(majorAxis);
			
			var sinBeta:Number = Math.sin(offsetAngle - AM_PI / 2);
			var cosBeta:Number = Math.cos(offsetAngle - AM_PI / 2);
			
			var sweepAngle:Number = endAngle - startAngle;
			var closed:Boolean = sweepAngle  == AM_PI * 2;
			var solid:Boolean = false;
			var inc:Number = sweepAngle / Number( closed ? numSegs : numSegs - 1);
			
			for (var i:int = 0; i < numSegs; i++) 
			{
				var alpha:Number = i * inc;
				var sinAlpha:Number = Math.sin(alpha + startAngle);
				var cosAlpha:Number = Math.cos(alpha + startAngle);
				
				var x:Number = center.x + (majorAxisLength * cosAlpha * cosBeta - minorAxisLength * sinAlpha * sinBeta);
				var y:Number = center.y + (majorAxisLength * cosAlpha * sinBeta + minorAxisLength * sinAlpha * cosBeta);
				
				verts.push(new amPoint2d(x, y));
			}
			
			return newPolylineBody(verts, thickness, mass, corners, ends, center, closed);
		}
			
		public static function newPolylineBody(vertices:Vector.<amPoint2d>, thickness:Number = 1, mass:Number = 0, corners:uint = CORNERS_SHARP, ends:uint = ENDS_SQUARE, registrationPoint:amPoint2d = null, closed:Boolean = false):qb2Body
		{
			var body:qb2Body = new qb2Body();
			registrationPoint ? body.position = registrationPoint : body.position.copy(vertices[0]);
			
			if ( thickness == 0 )
			{
				if ( closed )
				{
					vertices.push(vertices[0].clone());
				}
				var poly:qb2PolygonShape = new qb2PolygonShape();
				poly.set(vertices, registrationPoint.clone(), false);
				poly.position.set(0, 0);
				body.addObject(poly);
				
				if ( closed )
				{
					vertices.pop();
				}
			}
			else if ( vertices.length == 2 )
			{
				var vec:amVector2d = vertices[1].minus(vertices[0]);
				var rect:qb2PolygonShape = newRectShape(vertices[1].midwayPoint(vertices[0]), thickness, vec.length, 0, vec.angle);
				rect.position.subtract(body.position);
				body.addObject(rect);
			}
			else
			{
				if ( closed )
				{
					vertices.push(vertices[0].clone(), vertices[1].clone());
				}
				
				const newVerts:Vector.<amPoint2d> = new Vector.<amPoint2d>();
				
				if ( corners == CORNERS_NONE || corners == CORNERS_ROUND )
				{
					var limit:int = (!closed ? vertices.length - 1 : vertices.length - 2);
					for (var i:int = 0; i < limit; i++) 
					{
						var point1:amPoint2d = vertices[i];
						var point2:amPoint2d = vertices[i + 1];
						vec = point2.minus(point1);
						rect = qb2Stock.newRectShape(point1.midwayPoint(point2), thickness, vec.length, 0, vec.angle);
						rect.position.subtract(body.position);
						body.addObject(rect);
						
						if ( corners == CORNERS_ROUND && i > 0 )
						{
							body.addObject(qb2Stock.newCircleShape(point1.clone().subtract(body.position), thickness / 2));
						}
					}
				}
				else
				{
					var polyVerts:Vector.<amPoint2d> = new Vector.<amPoint2d>();
					
					point1 = vertices[0];
					point2 = vertices[1];
					
					var seg:amLine2d = new amLine2d(point1, point2);
						
					if ( !closed )
					{
						var mover:amVector2d = seg.direction.setToPerpVector(1).scaleBy(thickness / 2);
						var elbow1:amPoint2d = seg.point1.clone().translateBy(mover);
						polyVerts.push(elbow1);
						mover.negate();
						var elbow2:amPoint2d = seg.point1.clone().translateBy(mover);
						polyVerts.push(elbow2);
					}
					else
					{
						var tailSeg:amLine2d = new amLine2d(vertices[vertices.length - 3], vertices[vertices.length - 2]);
						var firstJoint:amLine2d = tailSeg.bisector(seg, thickness, Infinity);
						polyVerts.push(firstJoint.point1, firstJoint.point2);
					}
					
					var lastBisector:amLine2d = new amLine2d(polyVerts[0].clone(), polyVerts[1].clone());
					
					for ( i = 0; i < vertices.length-2; i++) 
					{
						var nextSeg:amLine2d = new amLine2d(vertices[i + 1], vertices[i + 2]);
						
						var elbow:amLine2d = seg.bisector(nextSeg, thickness, Infinity);
						
						if ( seg.intersectsLine(new amLine2d(polyVerts[0], elbow.point2)) )
						{
							polyVerts.push(elbow.point2.clone(), elbow.point1.clone());
						}
						else
						{
							polyVerts.push(elbow.point1.clone(), elbow.point2.clone());
						}
						
						rect = newPolygonShape(polyVerts, seg.midpoint.clone());
						rect.position.subtract(body.position);
						body.addObject(rect);
						
						polyVerts.length = 0;
						
						
						polyVerts.push(elbow.point1, elbow.point2 );
						
						seg = nextSeg;
						lastBisector = elbow;
					}
					
					if ( !closed )
					{
						var lastSeg:amLine2d = seg;
						mover = lastSeg.direction.setToPerpVector(1).scaleBy(thickness / 2);
						elbow1 = lastSeg.point2.translatedBy(mover);
						mover.negate()
						elbow2 = lastSeg.point2.translatedBy(mover);
						
						if ( !lastSeg.intersectsLine(new amLine2d(polyVerts[0], elbow2)) )
						{
							polyVerts.push(elbow1, elbow2);
						}
						else
						{
							polyVerts.push(elbow2, elbow1);
						}
						
						rect = newPolygonShape(polyVerts, seg.midpoint.clone());
						rect.position.subtract(body.position);
						body.addObject(rect);
					}
				}
				
				if ( closed )
				{
					vertices.pop();
					vertices.pop();
				}
			}
			
			if ( closed )
			{
				if ( corners == CORNERS_ROUND )
				{
					body.addObject(qb2Stock.newCircleShape(vertices[0].clone().subtract(body.position), thickness / 2));	
				}
			}
			else
			{
				if ( ends == ENDS_ROUND )
				{
					body.addObject(qb2Stock.newCircleShape(vertices[0].clone().subtract(body.position), thickness / 2));
					body.addObject(qb2Stock.newCircleShape(vertices[vertices.length - 1].clone().subtract(body.position), thickness / 2));	
				}
			}
			
			if ( mass )
			{
				body.mass = mass;
			}
			
			return body;
		}
		
		public static function newRegularPolygonShape(center:amPoint2d, radius:Number, numSides:uint, mass:Number = 0, initRotation:Number = 0):qb2PolygonShape
		{
			var rotPoint:amPoint2d = center.clone();
			rotPoint.y -= radius;
			var inc:Number = (Math.PI * 2) / numSides;
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>(numSides, true);
			for ( var i:int = 0; i < numSides; i++ )
			{
				verts[i] = new amPoint2d();  
				verts[i].copy(rotPoint);
				rotPoint.rotateBy(inc, center);
			}
			
			var poly:qb2PolygonShape = new qb2PolygonShape();
			if ( mass )  poly.mass = mass;
			poly.set(verts, center);
			poly.rotation = initRotation;
			
			return poly;
		}
		
		public static function newIsoTriShape(base:amPoint2d, baseWidth:Number, height:Number, mass:Number = 0, initRotation:Number = 0):qb2PolygonShape
		{
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>(3, true);
			verts[0] = new amPoint2d();  verts[0].x = base.x - baseWidth / 2;  verts[0].y = base.y;
			verts[1] = new amPoint2d();  verts[1].x = base.x;  verts[1].y = base.y - height;
			verts[2] = new amPoint2d();  verts[2].x = base.x + baseWidth / 2;  verts[2].y = base.y;
			
			var poly:qb2PolygonShape = new qb2PolygonShape();
			if ( mass )  poly.mass = mass;
			poly.set(verts, base);
			poly.rotation = initRotation;
			
			return poly;
		}

		public static function newRoundedRectBody(center:amPoint2d, width:Number, height:Number, cornerRadius:Number, mass:Number = 0, initRotation:Number = 0):qb2Body
		{
			var body:qb2Body = new qb2Body();
			body.setTransform(center, initRotation);
			
			var point:amPoint2d = new amPoint2d();
			body.addObject(newRectShape(point.clone(), width, height - cornerRadius * 2));
			point.y = -height / 2 + cornerRadius / 2;
			body.addObject(newRectShape(point.clone(), width - cornerRadius * 2, cornerRadius));
			point.y = height / 2 - cornerRadius / 2;
			body.addObject(newRectShape(point.clone(), width - cornerRadius * 2, cornerRadius));
			
			point.set( -width / 2 + cornerRadius, -height / 2 + cornerRadius);
			body.addObject(newCircleShape(point.clone(), cornerRadius));
			point.set( width / 2 - cornerRadius, -height / 2 + cornerRadius);
			body.addObject(newCircleShape(point.clone(), cornerRadius));
			point.set( width / 2 - cornerRadius, height / 2 - cornerRadius);
			body.addObject(newCircleShape(point.clone(), cornerRadius));
			point.set( -width / 2 + cornerRadius, height / 2 - cornerRadius);
			body.addObject(newCircleShape(point.clone(), cornerRadius));
			
			if ( mass )  body.mass = mass;
			
			return body;
		}
		
		public static function newDebugWorld(gravity:amVector2d = null, debugDrawGraphics:srGraphics2d = null, debugDragSource:InteractiveObject = null, stageToMakeWalls:Stage = null, autoStart:Boolean = true):qb2World
		{
			var world:qb2World = new qb2World();
			if ( gravity )
				world.gravity = gravity;
				
			world.debugDrawGraphics = debugDrawGraphics;
			world.debugDragSource = debugDragSource;
			
			if ( stageToMakeWalls )
			{
				world.addObject(new qb2StageWalls(stageToMakeWalls));
			}
			
			if ( autoStart )
			{
				world.start();
			}
			
			return world;
		}
		
		public static function newCircleSoftPoly(center:amPoint2d, radius:Number, numSegments:uint = 12, mass:Number = 1, groupIndex:int = -1 ):qb2SoftPoly
		{
			var poly:qb2SoftPoly = new qb2SoftPoly();
			poly.setAsCircle(center, radius, numSegments, mass, groupIndex);
			return poly;
		}
		
		public static function newPillBody(center:amPoint2d, width:Number, height:Number, mass:Number = 0, initRotation:Number = 0):qb2Body
		{
			var body:qb2Body = new qb2Body();
			body.setTransform(center, initRotation);
			
			var point:amPoint2d = new amPoint2d();
			body.addObject
			(
				newRectShape(point.clone(), width - height, height),
				newCircleShape(point.clone().setX( -width/2 + height/2), height / 2),
				newCircleShape(point.clone().setX( width/2 - height/2), height / 2)
			);
			if ( mass )  body.mass = mass;
			
			return body;
		}
	}
}