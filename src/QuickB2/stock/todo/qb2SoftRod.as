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

package QuickB2.stock.todo 
{
	import As3Math.geo2d.*;
	import QuickB2.debugging.qb2DebugTraceSettings;
	import QuickB2.objects.*;
	import QuickB2.objects.tangibles.*;
	
	/** TODO: This should be like qb2SoftPoly, but for long narrow shapes.
	 * 
	 * @private
	 * @author Doug Koellmer
	 */	 
	public class qb2SoftRod extends qb2Group
	{
		public function qb2SoftRod(initBeg:amPoint2d, initEnd:amPoint2d, initWidth:Number = 10, initNumSegs:uint = 2, initMass:Number = 1, initContactGroupIndex:int = -1) 
		{
			set(initBeg, initEnd, initWidth, initNumSegs);
			if ( initMass )  mass = initMass;
			contactGroupIndex = initContactGroupIndex;
		}
		
		public function set(newBeg:amPoint2d, newEnd:amPoint2d, newWidth:Number = 10, newNumSegs:uint = 2):void
		{
			
		}
		
		public override function toString():String 
			{  return qb2DebugTraceSettings.formatToString(this, "qb2SoftRod");  }
	}
}