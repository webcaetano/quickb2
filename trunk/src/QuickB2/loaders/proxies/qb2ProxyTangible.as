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
	public class qb2ProxyTangible extends qb2ProxyObject
	{
		[Inspectable(defaultValue="default", type='String', name='mass (default=0.0 kg)')]
		public var _float_mass:String = "default";

		[Inspectable(defaultValue="default", type='String', name='density (default=0.0)')]
		public var _float_density:String = "default";

		[Inspectable(defaultValue="default", type='String', name='restitution (default=0.0)')]
		public var _float_restitution:String = "default";

		[Inspectable(defaultValue="default", type='String', name='contactCategoryFlags (default=0x0001)')]
		public var _uint_contactCategoryFlags:String = "default";

		[Inspectable(defaultValue="default", type='String', name='contactMaskFlags (default=0xFFFF)')]
		public var _uint_contactMaskFlags:String = "default";

		[Inspectable(defaultValue="default", type='String', name='contactGroupIndex (default=0)')]
		public var _int_contactGroupIndex:String = "default";

		[Inspectable(defaultValue="default", type='String', name='friction (default=0.2)')]
		public var _float_friction:String = "default";

		[Inspectable(defaultValue="default", type='String', name='frictionZ (default=0.0)')]
		public var _float_frictionZ:String = "default";

		[Inspectable(defaultValue="default", type='String', name='linearDamping (default=0.0)')]
		public var _float_linearDamping:String = "default";

		[Inspectable(defaultValue="default", type='String', name='angularDamping (default=0.0)')]
		public var _float_angularDamping:String = "default";
		
		[Inspectable(defaultValue="default", type='String', name='sliceFlags (default=0xFFFFFFFF)')]
		public var _uint_sliceFlags:String = "default";
		
		
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='hasFixedRotation (default=false)')]
		public var _bool_hasFixedRotation:String = "default";

		[Inspectable(defaultValue="default",enumeration="default,true,false", name='isBullet (default=false)')]
		public var _bool_isBullet:String = "default";

		[Inspectable(defaultValue="default",enumeration="default,true,false", name='allowSleeping (default=true)')]
		public var _bool_allowSleeping:String = "default";

		[Inspectable(defaultValue="default",enumeration="default,true,false", name='sleepingWhenAdded (default=false)')]
		public var _bool_sleepingWhenAdded:String = "default";

		[Inspectable(defaultValue="default",enumeration="default,true,false", name='isGhost (default=false)')]
		public var _bool_isGhost:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='isKinematic (default=false)')]
		public var _bool_isKinematic:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='allowComplexPolygons (default=true)')]
		public var _bool_allowComplexPolygons:String = "default";
		
		[Inspectable(defaultValue="default",enumeration="default,true,false", name='isDebugDraggable (default=true)')]
		public var _bool_isDebugDraggable:String = "default";
		
		
		
		
		
		// HANDLERS
		[Inspectable(defaultValue="", type='String')]
		public var _handler_preSolve:String = "";
		
		[Inspectable(defaultValue="", type='String')]
		public var _handler_postSolve:String = "";
		
		[Inspectable(defaultValue="", type='String')]
		public var _handler_contactStarted:String = "";
		
		[Inspectable(defaultValue="", type='String')]
		public var _handler_contactEnded:String = "";
		
		[Inspectable(defaultValue="", type='String')]
		public var _handler_massPropsChanged:String = "";
	}
}