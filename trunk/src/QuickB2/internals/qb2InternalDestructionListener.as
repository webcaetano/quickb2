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

package QuickB2.internals 
{
	import Box2DAS.Dynamics.b2DestructionListener;
	import Box2DAS.Dynamics.b2Fixture;
	import Box2DAS.Dynamics.Joints.b2FrictionJoint;
	import Box2DAS.Dynamics.Joints.b2Joint;
	import QuickB2.objects.joints.qb2Joint;
	import QuickB2.objects.tangibles.qb2Shape;
	
	import QuickB2.*;
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 * @private
	 */
	public class qb2InternalDestructionListener extends b2DestructionListener
	{
		qb2_friend static const JOINT_DESTROYED_IMPLICITLY:String = "joint destroyed implicitly";
		
		public override function SayGoodbyeJoint(j:b2Joint):void
		{
			if ( j is b2FrictionJoint )
			{
				j.m_userData.frictionJoint = null;
			}
			
			var joint:qb2Joint = j.m_userData as qb2Joint;
			
			j.SetUserData(JOINT_DESTROYED_IMPLICITLY);
			if ( joint )
			{
				joint.world._totalNumJoints--;
				joint.jointB2 = null;
			}
		}
		
		public override function SayGoodbyeFixture(f:b2Fixture):void
		{
			//--- Flags this fixture as "already destroyed" so qb2Shape doesn't have to do it again.  This happens e.g. when a body destroys all its fixtures implicitly.
			var shape:qb2Shape = f.GetUserData() as qb2Shape;
			shape.doNotDestroyList[f] = true;
		}
	}
}