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

package QuickB2 
{
	/**
	 * Global settings controlling various preferences and optimizations.
	 * 
	 * @author Doug Koellmer
	 */
	public class qb2_settings
	{
		/** Determines whether any event listeners attached to qb2Object's are by default set to weak.
		 * If true, a call like myObject.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, handler) is actually
		 * ammended to myObject.addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, handler, false, 0, true) internally.
		 * 
		 * @default true
		 */
		public static var useWeakListeners:Boolean = true;
		
		/** Set this to false if you'd like more optimized handling of polygons.  The caveat is that all your polygons must be
		 * 8 or less vertices, convex, counter-clockwise, and non-self-intersecting if you want them to work correctly.
		 * This specifically makes the adding of polygons to the world more efficient, not so much how they perform while in the world.
		 * 
		 * @default true
		 */
		public static var checkForNonStandardPolygons:Boolean = true;
	}
}