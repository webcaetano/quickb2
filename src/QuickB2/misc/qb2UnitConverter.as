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
	import As3Math.consts.*;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2UnitConverter
	{
		public static const SECONDS_PER_HOUR:Number    = 3600.0;
		public static const SECONDS_PER_MINUTE:Number  = 60.0
		
		public static const WATTS_TO_HORSEPOWER:Number = 745.699;
		public static const RADIANS_PER_REVOLUTION:Number = 2 * AM_PI;
		public static const MILES_PER_METER:Number     = 0.000621371192;
		
		public static function metersPerSecond_to_pixelsPerFrame(velocity:Number, pixelsPerMeter:Number, timeStep:Number):Number
		{
			return velocity * pixelsPerMeter * timeStep;
		}
		
		public static function pixelsPerFrame_to_metersPerSecond(velocity:Number, pixelsPerMeter:Number, timeStep:Number):Number
		{
			return velocity / pixelsPerMeter / timeStep;
		}
		
		public static function metersPerSecond_to_milesPerHour(velocity:Number):Number
		{
			return velocity * SECONDS_PER_HOUR * MILES_PER_METER;  
		}
		
		public static function milesPerHour_to_metersPerSecond(velocity:Number):Number
		{
			return velocity / SECONDS_PER_HOUR / MILES_PER_METER;  
		}
		
		public static function radsPerSec_to_RPM(radsPerSec:Number):Number
		{
			return radsPerSec * SECONDS_PER_MINUTE / RADIANS_PER_REVOLUTION;
		}
		
		public static function RPM_to_radsPerSec(rpm:Number):Number
		{
			return rpm / SECONDS_PER_MINUTE * RADIANS_PER_REVOLUTION;
		}
	}
}