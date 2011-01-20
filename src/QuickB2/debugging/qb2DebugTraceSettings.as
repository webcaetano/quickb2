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

package QuickB2.debugging 
{
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2DebugTraceSettings 
	{
		/// The two characters indicating the beginning and end of a class trace.
		public static var classEnclosures:String   = "[]";
		
		/// The two characters indicating the beginning and end of the variable list of a class.
		public static var varEnclosures:String     = "()";
		
		/// The character(s) to signify a variable's value.
		public static var equalityCharacter:String = "=";
		
		/// The character(s) delimiting the list of variables for a class.
		public static var varDelimiter:String      = ", ";
		
		/// Associates a list of class names to the variables that they should spit out for toString() calls.
		public static const classToVariableMap:Object = 
		{
			qb2World:            ["totalNumPolygons", "totalNumCircles", "totalNumJoints"],
			qb2Body:             ["mass", "position", "rotation", "linearVelocity", "angularVelocity", "numObjects"],
			qb2Group:            ["mass", "numObjects"],
			qb2CircleShape:      ["mass", "position", "rotation", "radius"],
			qb2PolygonShape:     ["mass", "position", "rotation", "numVertices"],
			
			qb2Chain:            ["mass", "numLinks", "length", "linkWidth", "linkThickness", "linkLength"],
			qb2FollowBody:       ["position", "rotation", "targetPosition", "targetRotation"],
			qb2SoftPoly:         ["mass", "numVertices", "subdivision", "isCircle"],
			qb2SoftRod:          ["mass", "numSegments", "length", "width"],
			qb2TripSensor:       ["position", "tripTime", "numVisitors", "numTrippedVisitors"],
			qb2Terrain:      	 ["position", "frictionZMultiplier"],
			qb2SoundField:     	 ["position", "frictionZMultiplier"],
			qb2StageWalls:       null,
			
			qb2Joint:            ["collideConnected", "isActive"],
			qb2DistanceJoint:    ["length", "isRope", "localAnchor1", "localAnchor2", "isActive"],
			qb2MouseJoint:       ["worldTarget", "localAnchor", "isActive"],
			qb2PistonJoint:      ["springK", "hasLimits", "localAnchor1", "localAnchor2", "isActive"],
			qb2RevoluteJoint:    ["springK", "hasLimits", "localAnchor1", "localAnchor2", "isActive"],
			qb2WeldJoint:        ["localAnchor1", "localAnchor2", "isActive"],
			
			qb2GravityField:     [],
			qb2GravityWell:      [],
			qb2PlanetaryGravity: [],
			qb2Vibrator:         [],
			qb2Vortex:           [],
			qb2Wind:             [],
			
			qb2Event:            ["type"],
			qb2ContainerEvent:   ["type", "parentObject", "childObject"],
			qb2ContactEvent:     ["type", "localObject", "otherObject", "contactPoint", "contactNormal"],
			qb2MassEvent:        ["type", "affectedObject", "massChange", "densityChange", "areaChange"],
			qb2RayCastEvent:     ["type"],
			qb2SubContactEvent:  ["type", "ancestorGroup", "contactPoint", "contactNormal"],
			qb2TripSensorEvent:  ["type", "sensor", "visitingObject"],
			qb2UpdateEvent:      ["type", "object"]
		};
		
		/// Creates a string useful for trace()ing with custom variables of your choice.
		public static function formatToStringWithCustomVars(object:Object, ... varNames):String
		{
			var className:String = getClassName(object);
			return makeCompleteString(object, className, varNames);
		}
		
		/// Creates a string useful for trace()ing.  Variables for QuickB2 classes are displayed as defined in classToVariableMap.
		public static function formatToString(object:Object, baseClass:String):String
		{
			var className:String = getClassName(object);
			return makeCompleteString(object, className, classToVariableMap[baseClass]);
		}

		private static function getClassName(object:Object):String
		{
			var className:String = object.constructor.toString();
			className = className.substring(7, className.length - 1); // strips the [class *] stuff off, leaving just the class name.
			return className;
		}
		
		private static function makeCompleteString(object:Object, className:String, varNames:Array):String
		{
			var toReturn:String = classEnclosures.charAt(0) + className + varEnclosures.charAt(0);
			
			if ( varNames )
			{
				for (var i:int = 0; i < varNames.length; i++)
				{
					var varName:String = varNames[i] as String;
				
					if ( !varName )  continue;
					
					var variable:Object = object[varName];
					toReturn += varName + equalityCharacter + variable;
					
					if ( i < varNames.length - 1 )
					{
						toReturn += varDelimiter;
					}
				}
			}
			else
			{
				toReturn += "no variables provided";
			}
			
			toReturn += varEnclosures.charAt(1) + classEnclosures.charAt(1);
			
			return toReturn;
		}
	}
}