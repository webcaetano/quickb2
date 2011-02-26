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

package QuickB2.effects 
{
	import As3Math.geo2d.*;
	import QuickB2.debugging.*;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2WindField extends qb2EffectField
	{
		/** The wind direction and speed.
		 * @default zero-length vector.
		 */
		public var windVector:amVector2d = new amVector2d();
		
		/** The air density in kg/m^3, which effects how strong the wind is.
		 * @default 1.22521 kg/m^3 (standard air density at 15 degrees Celcius at sea level.
		 */
		public var airDensity:Number = 1.22521;
		
		public override function apply(toObject:qb2Tangible):void
		{
			if ( !shouldApply(toObject) )  return;
			
			utilTraverser.root = toObject;
			
			while (utilTraverser.hasNext )
			{
				var currObject:qb2Object = utilTraverser.currentObject;
				
				if ( !(currObject is qb2Tangible) )
				{
					utilTraverser.next(false);
					continue;
				}
				else if ( currObject is qb2IRigidObject )
				{
					var asRigid:qb2IRigidObject = currObject as qb2IRigidObject;
					
					if ( asRigid.ancestorBody )
					{
						asRigid.ancestorBody.applyForce(asRigid.parent.getWorldPoint(asRigid.centerOfMass), gravityVector.scaledBy(asRigid.mass));
					}
					else
					{
						asRigid.applyForce(asRigid.centerOfMass, gravityVector.scaledBy(asRigid.mass));
					}
					
					utilTraverser.next(false);
				}
				else
				{
					utilTraverser.next(true);
				}
			}
		}
		
		public override function clone():qb2Object
		{
			var cloned:qb2WindField = super.clone() as qb2WindField;
			
			cloned.windVector.copy(this.windVector);
			cloned.airDensity = this.airDensity;
			
			return cloned;
		}
		
		public override function toString():String 
			{  return qb2DebugTraceUtils.formatToString(this, "qb2WindField");  }
		
	}
}