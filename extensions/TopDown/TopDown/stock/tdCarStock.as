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

package TopDown.stock 
{
	import As3Math.geo2d.*;
	import flash.display.*;
	import QuickB2.objects.qb2Object;
	import QuickB2.stock.*;
	import TopDown.ai.brains.*;
	import TopDown.ai.controllers.*;
	import TopDown.carparts.*;
	import TopDown.objects.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdCarStock
	{
		public static function newBasicCarBody(center:amPoint2d, width:Number = 60, height:Number = 120, initRotation:Number = 0, mass:Number = 1500):tdCarBody
		{
			var carBody:tdCarBody = new tdCarBody();
			carBody.position.copy(center);
			carBody.rotation = initRotation;
			carBody.addObject(qb2Stock.newRectShape(new amPoint2d(), width, height, mass));
			
			carBody.engine = new tdEngine();
			carBody.tranny = new tdTransmission();
			carBody.tranny.gearRatios = Vector.<Number>([3.5, 3.5, 3, 2.5, 2, 1.5, 1]);
			carBody.addObjects(newBasicTwoWheelDriveBase(new amPoint2d(), width * .9, height * .5));
			
			var curve:tdTorqueCurve = carBody.engine.torqueCurve;
			curve.addEntry(1000, 300);
			curve.addEntry(2000, 310);
			curve.addEntry(3000, 320);
			curve.addEntry(4000, 325);
			curve.addEntry(5000, 330);
			curve.addEntry(6000, 325);
			curve.addEntry(7000, 320);
			return carBody;
		}
		
		public static function newBasicControllableCarBody(keySource:Stage, center:amPoint2d, width:Number = 60, height:Number = 120, initRotation:Number = 0, mass:Number = 1500):tdCarBody
		{
			var carBody:tdCarBody = newBasicCarBody(center, width, height, initRotation, mass);
			var brain:tdControllerBrain = new tdControllerBrain();
			var controller:tdKeyboardController = new tdKeyboardCarController(keySource);
			brain.addController(controller);
			carBody.brain = brain;
			
			return carBody;
		}
		
		public static function newBasicTwoWheelDriveBase(center:amPoint2d, baseWidth:Number, baseHeight:Number, tireWidth:Number = 8, tireRadius:Number = 10, friction:Number = 1.5, rollingFriction:Number = .1):Vector.<qb2Object>
		{
			var tires:Vector.<qb2Object> = new Vector.<qb2Object>(4, true);
			tires[0] = new tdTire(center.clone().incX(-baseWidth/2).incY(-baseHeight/2), tireWidth, tireRadius, true, true, false, friction, rollingFriction);
			tires[1] = new tdTire(center.clone().incX(baseWidth/2).incY(-baseHeight/2), tireWidth, tireRadius, true, true, false, friction, rollingFriction);
			tires[2] = new tdTire(center.clone().incX(baseWidth/2).incY(baseHeight/2), tireWidth, tireRadius, false, false, true, friction, rollingFriction);
			tires[3] = new tdTire(center.clone().incX( -baseWidth / 2).incY(baseHeight / 2), tireWidth, tireRadius, false, false, true, friction, rollingFriction);
			
			return tires;
		}
	}
}