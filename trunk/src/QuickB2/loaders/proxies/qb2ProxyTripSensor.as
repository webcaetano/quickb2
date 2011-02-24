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

package QuickB2.loaders.proxies
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2ProxyTripSensor extends qb2ProxyBody
	{
		public function qb2ProxyTripSensor():void
		{
			defaultClassName = "QuickB2.stock.qb2TripSensor";
		}
		
		[Inspectable(defaultValue="default", type='String', name='tripTime (default=0.0 seconds)')]
		public var _float_tripTime:String = "default";
		
		[Inspectable(defaultValue="", type='String')]
		public var _handler_sensorTripped:String = "";
		
		[Inspectable(defaultValue="", type='String')]
		public var _handler_sensorEntered:String = "";
		
		[Inspectable(defaultValue="", type='String')]
		public var _handler_sensorExited:String = "";
	}
}