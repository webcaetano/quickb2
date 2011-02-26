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

package QuickB2.misc 
{
	import As3Math.geo2d.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2KillBox extends amBoundBox2d
	{
		public static const POSITION_LEAVES:uint        = 0x00000001;
		public static const CENTROID_LEAVES:uint        = 0x00000002;
		public static const BOUND_BOX_LEAVES:uint       = 0x00000004;
		public static const GEOMETRY_LEAVES:uint        = 0x00000008;
		public static const ACTOR_POSITION_LEAVES:uint  = 0x00000010;
		public static const ACTOR_BOUND_BOX_LEAVES:uint = 0x00000020;
		
		public var conditionFlag:uint = 0;
		
		public var ignoreStatics:Boolean = true;
		
		public function qb2KillBox(initMin:amPoint2d = null, initMax:amPoint2d = null, initConditionFlag:uint = POSITION_LEAVES )
		{
			super(initMin, initMax);
			
			conditionFlag = initConditionFlag;
		}
	}
}