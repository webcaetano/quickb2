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
	public class qb2ProxyPistonJoint extends qb2ProxyJoint
	{
		[Inspectable(defaultValue="default", name='springK (default=0.0)')]
		public var springK:String = "default";
		
		[Inspectable(defaultValue="default", name='springDamping (default=0.0)')]
		public var springDamping:String = "default";
		
		[Inspectable(defaultValue = "default", name = 'springLength (default based on object seperation')]
		public var springLength:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='springCanFlip (default=false)')]
		public var springCanFlip:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='dampenSpringJitter (default=false)')]
		public var dampenSpringJitter:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='optimizedSpring (default=true)')]
		public var optimizedSpring:String = "default";
		
		
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='syncedObjectRotation (default=false)')]
		public var syncedObjectRotation:String = "default";
		
		[Inspectable(defaultValue="default", name='lowerLimit (default=-Infinity)')]
		public var lowerLimit:String        = "default";
		
		[Inspectable(defaultValue="default", name='upperLimit (default=Infinity)')]
		public var upperLimit:String        = "default";
		
		[Inspectable(defaultValue="default", name='maxPistonForce (default=0.0)')]
		public var maxPistonForce:String    = "default";
		
		[Inspectable(defaultValue="default", name='targetPistonSpeed (default=0.0)')]
		public var targetPistonSpeed:String = "default";
		
		
		
		[Inspectable(defaultValue="")]
		public var overrideObject1:String = "";
		
		[Inspectable(defaultValue="")]
		public var overrideObject2:String = "";
	}
}