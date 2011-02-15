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
	import As3Math.general.*;
	import As3Math.geo2d.*;
	import flash.display.*;
	import QuickB2.debugging.*;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.objects.tangibles.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2SoftPoly extends qb2Group
	{
		private var _subdivision:uint = 1;
		private var _numVertices:uint = 0;
		
		private var revJoints:Vector.<qb2RevoluteJoint> = new Vector.<qb2RevoluteJoint>();
		
		public var drawSplinarOutlines:Boolean = true;
		
		private var _isCircle:Boolean = false;
		
		public function qb2SoftPoly():void
		{
		}
		
		public override function clone():qb2Object
		{
			//--- Here we have to make sure to populate the shapes array so that the draw function has something to go off of.
			var jelloPoly:qb2SoftPoly = super.clone() as qb2SoftPoly;
			var numObjects:uint = jelloPoly.numObjects;
			for (var i:int = 0; i < numObjects; i++)
			{
				var ithObj:qb2Object = jelloPoly.getObjectAt(i);
				if( ithObj is qb2RevoluteJoint )
					jelloPoly.revJoints.push(ithObj as qb2RevoluteJoint);
			}
			jelloPoly.revJoints.unshift(jelloPoly.revJoints.pop());  // move the last joint to the beginning...just makes looping more intuitive
			
			jelloPoly._isCircle    = this._isCircle;
			jelloPoly._numVertices = this._numVertices;
			jelloPoly._subdivision = this._subdivision;
			jelloPoly.drawSplinarOutlines = this.drawSplinarOutlines;
			
			return jelloPoly;
		}
		
		public function set(vertices:Vector.<amPoint2d> = null, initSubdivision:uint = 1, initMass:Number = 1, initGroupIndex:int = -1):qb2SoftPoly
		{
			_isCircle = false;
			removeAllObjects();
			revJoints.length = 0;
			_numVertices = 0;
			_subdivision = 1;
			
			if ( !vertices || vertices.length < 3)  return null;
			
			_numVertices = vertices.length;
			_subdivision = initSubdivision;
			contactGroupIndex = initGroupIndex;
			
			var poly:amPolygon2d = new amPolygon2d(vertices);
			var centroid:amPoint2d = poly.centerOfMass;
			
			var lastBody:qb2Body = null;
			
			for (var i:int = 0; i < vertices.length; i++) 
			{
				var ithVert:amPoint2d = vertices[i];
				var nextVert:amPoint2d = vertices[i < vertices.length - 1 ? i + 1 : 0];
				
				if ( _subdivision > 1 )
				{
					var vec:amVector2d = nextVert.minus(ithVert).scaleBy(1 / Number(_subdivision));
					var movePnt:amPoint2d = ithVert.clone();
					for ( var j:int = 0; j < _subdivision; j++ )
					{
						var nextMove:amPoint2d = movePnt.translatedBy(vec);
						
						var body:qb2Body = new qb2Body();
						body.position.copy(centroid);
						var shape:qb2PolygonShape = new qb2PolygonShape();
						shape.set(Vector.<amPoint2d>([movePnt.clone(), nextMove.clone(), centroid.clone()]));
						shape.position.subtract(body.position); // move it to body's local coordinates.
						body.addObject(shape);
						addObject(body);
		
						if ( this.numObjects > 1 )  stitch(lastBody, body, movePnt);
						
						movePnt.translateBy(vec);
						
						lastBody = body;
					}
				}
				else
				{
					body = new qb2Body();
					body.position.copy(centroid);
					shape = qb2Stock.newPolygonShape(Vector.<amPoint2d>([ithVert.clone(), nextVert.clone(), centroid.clone()]));
					shape.position.subtract(body.position); // move it to body's local coordinates.
					body.addObject(shape);
					addObject(body);
					
					if ( this.numObjects > 1 )  stitch(lastBody, body, ithVert);
					
					lastBody = body;
				}
			}
			
			stitch(lastBody, this.getObjectAt(0) as qb2Body, vertices[0]);
			
			revJoints.unshift(revJoints.pop());  // move the last joint to the beginning...just makes looping more intuitive
			
			this.mass = initMass;
			
			return this;
		}
		
		private function stitch(body1:qb2Body, body2:qb2Body, point:amPoint2d):void
		{
			var joint:qb2RevoluteJoint = new qb2RevoluteJoint(body1, body2, point);
			joint.springK = _springK;
			joint.springDamping = _springDamping;
			//joint.lowerAngle = -RAD_90;
			//joint.upperAngle = RAD_90;
			joint.setLimits( -_jointLimitRange/2, _jointLimitRange/2);
			addObject(joint);
			revJoints.push(joint);
		}
		
		public function get springK():Number
			{  return _springK;  }
		public function set springK(value:Number):void
		{
			_springK = value;
			
			for (var i:int = 0; i < revJoints.length; i++) 
			{
				revJoints[i].springK = _springK;
			}
		}
		private var _springK:Number   = 10;
		
		public function get springDamping():Number
			{  return _springDamping;  }
		public function set springDamping(value:Number):void
		{
			_springDamping = value;
			
			for (var i:int = 0; i < revJoints.length; i++) 
			{
				revJoints[i].springDamping = _springDamping;
			}
		}
		private var _springDamping:Number   = .15;
		
		public function get jointLimitRange():Number
			{  return _jointLimitRange;  }
		public function set jointLimitRange(value:Number):void
		{
			_jointLimitRange = value;
			
			var div2:Number = _jointLimitRange / 2;
			for (var i:int = 0; i < revJoints.length; i++) 
			{
				revJoints[i].setLimits( -div2, div2);
			}
		}
		private var _jointLimitRange:Number   = RAD_10*2;
		
		
		
		public function setAsCircle(center:amPoint2d, radius:Number, numSegments:uint = 12, initMass:Number = 1, initGroupIndex:int = -1):qb2SoftPoly
		{
			var rotPoint:amPoint2d = center.clone();
			rotPoint.y -= radius;
			var inc:Number = (Math.PI * 2) / numSegments;
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>(numSegments, true);
			for ( var i:int = 0; i < numSegments; i++ )
			{
				verts[i] = new amPoint2d();  
				verts[i].copy(rotPoint);
				rotPoint.rotateBy(inc, center);
			}

			set(verts, 1, initMass, initGroupIndex);
			
			_isCircle = true;
			
			return this;
		}
		
		public function setAsRect(center:amPoint2d, width:Number, height:Number, numSubdivisions:uint = 2, initMass:Number = 1, initGroupIndex:int = -1):qb2SoftPoly
		{
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>(4, true);
			verts[0] = new amPoint2d(center.x - width / 2, center.y - height / 2);
			verts[1] = new amPoint2d(center.x + width / 2, center.y - height / 2);
			verts[2] = new amPoint2d(center.x + width / 2, center.y + height / 2);
			verts[3] = new amPoint2d(center.x - width / 2, center.y + height / 2);
			
			set(verts, numSubdivisions, initMass, initGroupIndex);
			
			return this;
		}
		
		public function setAsStar(center:amPoint2d, outerRadius:Number, innerRadius:Number, numPoints:uint = 6, numSubdivisions:uint = 2, initMass:Number = 1, initGroupIndex:int = -1):qb2SoftPoly
		{
			const verts:Vector.<amPoint2d> = new Vector.<amPoint2d>();
			
			var startOuter:amPoint2d = center.clone().incY( -outerRadius);
			var startInner:amPoint2d = center.clone().incY( -innerRadius);
			
			var incAngle:Number = (AM_PI * 2) / (numPoints as Number);
			startInner.rotateBy(incAngle / 2, center);
			for (var i:int = 0; i < numPoints; i++) 
			{
				verts.push(startOuter.rotatedBy(i * incAngle, center));
				verts.push(startInner.rotatedBy(i * incAngle, center));
			}
			
			return set(verts, numSubdivisions, initMass, initGroupIndex);
		}
		
		public function get subdivision():uint
		{
			return _subdivision;
		}
		
		public function get numVertices():uint
		{
			return _numVertices;
		}
		
		public function get isCircle():Boolean
		{
			return _isCircle;
		}
		
		public override function draw(graphics:Graphics):void
		{
			if ( !drawSplinarOutlines )
			{
				var basePoint:amPoint2d = revJoints[0].getWorldAnchor();
				graphics.moveTo(basePoint.x, basePoint.y);
				
				for (var i:int = 1; i < revJoints.length; i++) 
				{
					var worldPoint:amPoint2d = revJoints[i].getWorldAnchor();
					graphics.lineTo(worldPoint.x, worldPoint.y);
				}
				
				graphics.lineTo(basePoint.x, basePoint.y);
			}
			else
			{
				if ( _subdivision == 1 )
				{
					var verts:Vector.<amPoint2d> = new Vector.<amPoint2d>(revJoints.length, true);
					
					for (i = 0; i < revJoints.length; i++) 
					{
						verts[i] = revJoints[i].getWorldAnchor();
					}
					
					amGraphics.drawClosedCubicSpline(graphics, verts);
				}
				else
				{
					basePoint = revJoints[0].getWorldAnchor();
					graphics.moveTo(basePoint.x, basePoint.y);
				
					verts = new Vector.<amPoint2d>();
					var count:uint = 0;
					for ( i = 0; i <= revJoints.length;  i++) 
					{
						var revJoint:qb2RevoluteJoint = revJoints[i < revJoints.length ? i : 0];
						var vertex:amPoint2d = revJoint.getWorldAnchor();
						verts.push(vertex);
						
						count++;
						
						if ( count > _subdivision )
						{
							var tangent:amVector2d = vertex.minus(verts[0]).scaleBy(1 / Number(_subdivision));
							amGraphics.drawCubicSpline(graphics, tangent, tangent, verts, false);
							verts.length = 0;
							verts.push(vertex);
							count = 1;
						}
					}
				}
			}
		}
		
		public override function drawDebug(graphics:Graphics):void
		{
			if ( !revJoints.length )  return;
			
			var drawFlags:uint = qb2_debugDrawSettings.flags;
			
			if ( !(drawFlags & qb2_debugDrawFlags.OUTLINES) && !(drawFlags & qb2_debugDrawFlags.FILLS))  return;
			
			var staticShape:Boolean = mass == 0;
			
			if ( drawFlags & qb2_debugDrawFlags.OUTLINES )
				graphics.lineStyle(qb2_debugDrawSettings.lineThickness, debugOutlineColor, qb2_debugDrawSettings.outlineAlpha);
			else
				graphics.lineStyle();
			if ( drawFlags & qb2_debugDrawFlags.FILLS )
				graphics.beginFill(debugFillColor, qb2_debugDrawSettings.fillAlpha);
				
			draw(graphics);
			
			graphics.endFill();
			
			if ( _isCircle )
			{
				if ( (drawFlags & qb2_debugDrawFlags.OUTLINES) && (drawFlags & qb2_debugDrawFlags.CIRCLE_SPOKES) )
				{
					//graphics.lineStyle(qb2_debugDrawSettings.lineThickness, staticShape ? qb2_debugDrawSettings.staticOutlineColor : qb2_debugDrawSettings.dynamicOutlineColor, qb2_debugDrawSettings.outlineAlpha);
					
					var center:amPoint2d = centerOfMass;
					
					if ( !center )  return;
					
					var spokeFlags:Array =
					[
						qb2_debugDrawFlags.CIRCLE_SPOKE_1, qb2_debugDrawFlags.CIRCLE_SPOKE_2,
						qb2_debugDrawFlags.CIRCLE_SPOKE_3, qb2_debugDrawFlags.CIRCLE_SPOKE_4
					];
					
					var fourth:int = revJoints.length / 4;
					for (var i:int = 0; i < spokeFlags.length; i++) 
					{
						if ( drawFlags & spokeFlags[i] )
						{
							var point:amPoint2d = revJoints[i * fourth].getWorldAnchor();
							graphics.moveTo(point.x, point.y);
							graphics.lineTo(center.x, center.y);
						}
					}
				}
			}
			
			if ( drawFlags & qb2_debugDrawFlags.DECOMPOSITION )
			{
				for (var j:int = 0; j < numObjects; j++) 
				{
					var jthObject:qb2Object = getObjectAt(j);
					
					if ( jthObject is qb2IRigidObject )
					{
						jthObject.draw(graphics);
					}
				}
			}
		}
		
		public override function toString():String
			{  return qb2DebugTraceSettings.formatToString(this, "qb2SoftPoly");  }
	}
}