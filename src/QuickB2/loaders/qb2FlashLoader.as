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

package QuickB2.loaders
{
	import As3Math.consts.*;
	import As3Math.geo2d.*;
	import flash.display.*;
	import flash.geom.*;
	import flash.utils.*;
	import QuickB2.*;
	import QuickB2.events.*;
	import QuickB2.loaders.proxies.*;
	import QuickB2.loaders.proxies.geoproxies.*;
	import QuickB2.misc.acting.qb2IActor;
	import QuickB2.objects.*;
	import QuickB2.objects.joints.*;
	import QuickB2.objects.tangibles.*;
	import QuickB2.stock.*;
	import revent.rEventDispatcher;
	
	use namespace qb2_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class qb2FlashLoader extends rEventDispatcher
	{
		public function qb2FlashLoader():void {}
		
		 //--- Stores class->object relationship. If user provides a Class as the source, then objects made
		 //--- are backed up in here and cloned upon subsequent requests for the same Class.
		private static const cache:Dictionary = new Dictionary();
		
		private var _loadingInProgress:Boolean = false;
		private var proxyDict:Dictionary = null;
		
		/// Whether empty proxies are automatically removed from their parents.
		public var removeEmptyProxies:Boolean = true;
		
		public final function loadObject(source:*, chunkSize:uint = uint.MAX_VALUE):qb2Object
		{
			if ( _loadingInProgress )  throw new Error("A load is already in progress.");
			
			if ( !movieClipVarsBuilt )
			{
				buildMovieClipVars();
			}
			
			_loadingInProgress = true;
			
			var newSource:* = null;
			if ( (source is Class) || (source is qb2Proxy) )
				newSource = source;
			else if ( source is String )
				newSource = getDefinitionByName(source as String);
			else
			{
				_loadingInProgress = false;
				throw new Error("Invalid source provided.");
			}
			
			if ( newSource is Class )
			{
				if ( cache[newSource] )
				{
					_loadingInProgress = false;
					var cachedObject:qb2Object = cache[newSource] as qb2Object;
					var clone:qb2Object = cachedObject is qb2Joint ? (cachedObject as qb2Joint).clone() : (cachedObject as qb2Tangible).clone();
					finishObject(clone);
					return clone;
				}
			}
			
			var i:int, j:int;
			
			const objectDict:Dictionary     = new Dictionary(true);  // stores objectProxy->object and object->tags
			proxyDict = new Dictionary(true);  // stores joint->jointProxy
			
			//--- Do a breadth first (or level-order) traversal of the display hierarchy tree using a FIFO queue.
			//--- Basically, this goes through, finds proxies and tags, and makes usable physics objects out of them.
			var queue:Vector.<DisplayObject> = new Vector.<DisplayObject>();
			var baseProxy:qb2ProxyObject = newSource is qb2ProxyObject ? newSource : (new newSource) as qb2ProxyObject;
			if ( !baseProxy )  throw new Error("Class provided must extend from qb2ProxyObject.");
			queue.unshift(baseProxy);
			while ( queue.length )
			{
				var subclip:DisplayObject = queue.shift();
				
				var type:uint = establishType(subclip);
				
				if ( !type )  continue;
				
				var tags:Vector.<qb2Proxy>;
				
				if( type & USER_PROXY )
				{
					foundUserProxy(objectDict[subclip.parent] as qb2ObjectContainer, subclip as qb2ProxyUserObject );
					continue; // no need to go further with this proxy if we don't know what it is...subclasses will do what they want with this.
				}
				else if ( type & EDITOR_PROXY )
				{
					if ( subclip.parent )  subclip.parent.removeChild(subclip);
					continue; // this proxy was just there to help the user keep things organized in Flash Pro...it has no bearing on the runtime and can be removed.
				}
				else if ( !(type & OBJECT) )
				{
					continue;
				}
				else
				{
					popUp(subclip);
					tags = getTags(subclip);
				}
				
				var object:qb2Object = null;
				var subclipRad:Number = subclip.rotation * TO_RAD;
				//trace(subclip.x);
				
				var overriddenClassName:String = getClassName(subclip as qb2Proxy, tags);
				
				if ( type & JOINT )
				{
					var jointType:uint = establishJointType(subclip);
					var newJoint:qb2Joint = null;
					
					if ( jointType & DIST_JOINT )
					{
						newJoint = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2DistanceJoint();
					}
					else if ( jointType & PISTON_JOINT )
					{
						newJoint = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2PistonJoint();
					}
					else if ( jointType & REV_JOINT )
					{
						newJoint = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2RevoluteJoint();
					}
					else if ( jointType & WELD_JOINT )
					{
						newJoint = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2WeldJoint();
					}
					else if ( jointType & MOUSE_JOINT )
					{
						newJoint = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2MouseJoint();
					}
					
					if ( newJoint )
					{
						var jointProxy:qb2ProxyJoint = subclip as qb2ProxyJoint;
						object = newJoint;
						
						var anchorPoints:Vector.<amPoint2d> = new Vector.<amPoint2d>();
						var numChildren:int = jointProxy.numChildren;
						for ( j = 0; j < numChildren; i++) 
						{
							var jointChild:DisplayObject = jointProxy.getChildAt(i);
							
							if ( jointChild is qb2ProxyGeoJointAnchor )
							{
								var anchor:qb2ProxyGeoJointAnchor = jointChild as qb2ProxyGeoJointAnchor;
								popUp(anchor);
								anchorPoints.push(new amPoint2d(anchor.x, anchor.y));
							}
						}
						
						//--- Store the anchor points as locals for now, even though they represent globalish points.
						if ( anchorPoints.length )
						{
							newJoint._localAnchor1.copy(anchorPoints[0]);
							if ( newJoint._localAnchor2 )
								newJoint._localAnchor2.copy(anchorPoints.length > 1 ? anchorPoints[1] : anchorPoints[0]);
						}
					}
					
					subclip.parent.removeChild(subclip); // joints don't have actors, so just get rid of it.
				}
				else if ( type == SHAPE )
				{
					//--- Determine what shape type this is, based on geometry proxy information, fire off user proxy encounters,
					//--- and remove editor proxies.  This isn't done in the outer 'queue loop' because we're not interested in
					//--- penetrating the display hierarchy tree any further.
					var proxyVertsFound:Vector.<qb2ProxyGeoVertex> = null;
					var proxyGeoCircle:qb2ProxyGeoCircle = null;
					var shapeProxy:MovieClip = subclip as MovieClip;
					shapeProxy.rotation = 0;
					var userProxies:Vector.<qb2ProxyUserObject> = null;
					for ( i = 0; i < shapeProxy.numChildren; i++)
					{
						var proxyChild:DisplayObject = shapeProxy.getChildAt(i);
						
						if ( proxyChild is qb2ProxyGeoVertex )
						{
							if ( !proxyVertsFound )
							{
								proxyVertsFound = new Vector.<qb2ProxyGeoVertex>();
							}
							
							var proxyVert:qb2ProxyGeoVertex = proxyChild as qb2ProxyGeoVertex;
							popUp(proxyVert);
							
							//--- Go through existing vertex proxies found, and add this one in order.
							var inserted:Boolean = false;
							for ( j = 0; j < proxyVertsFound.length; j++) 
							{
								var jthProxyVert:qb2ProxyGeoVertex = proxyVertsFound[j];
								if ( proxyVert.order < jthProxyVert.order )
								{
									//--- Insert vertices in order.
									proxyVertsFound.splice(j, 0, proxyVert);
									inserted = true;
									break;
								}
							}
							
							//--- If the vertex proxy's order was higher than all existing ones, just push it to the end of the list.
							if ( !inserted )
							{
								proxyVertsFound.push(proxyVert);
							}
							
							//--- Never want to show actual vertex proxies on the actor.
							shapeProxy.removeChildAt(i--);
						}
						else if ( proxyChild is qb2ProxyGeoCircle )
						{
							proxyGeoCircle = proxyChild as qb2ProxyGeoCircle;
							popUp(proxyGeoCircle);
							proxyGeoCircle.rotation = 0;  // have to zero-out the rotation here, otherwise height/width of the circle aren't accurate because they're taken from the rotated bounding box of the circle.
							shapeProxy.removeChildAt(i--);
						}
						else if ( proxyChild is qb2ProxyUserObject )
						{
							if ( !userProxies )  userProxies = new Vector.<qb2ProxyUserObject>();
							
							userProxies.push(proxyChild as qb2ProxyUserObject );
						}
						else if ( proxyChild is qb2ProxyEditorObject )
						{
							shapeProxy.removeChildAt(i--);
						}
					}
					shapeProxy.rotation = subclipRad * TO_DEG;
					
					//--- Actually make the shape if any proxy information was found, which it definitely should have been.
					//--- If not, most likely the user did something wrong, but we'll ignore it without making them pay.
					var shape:qb2Shape = null;
					if ( proxyGeoCircle )
					{
						var circleShape:qb2CircleShape = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2CircleShape();					
						circleShape.set(new amPoint2d(subclip.x, subclip.y), proxyGeoCircle.width / 2); // position is taken off the shape proxy, and not the circle proxy...this means the circle proxy has to be at (0,0) within the shape for things to be accurate.
						shape = circleShape;
						
					}
					else if ( proxyVertsFound )
					{
						//--- Find which vertex, if any, is the last in the closed loop defining this polygon.
						//--- If no last vertex is encountered, it means that the polygon is meant to be non-closed.
						var closed:Boolean = false;
						var verts:Vector.<amPoint2d> = new Vector.<amPoint2d>();
						for ( i = 0; i < proxyVertsFound.length; i++) 
						{
							proxyVert = proxyVertsFound[i];
							
							verts.push(new amPoint2d(proxyVert.x, proxyVert.y));
							if ( proxyVert.lastInLoop )
							{
								closed = true;
								break;
							}
						}
						
						//--- Make the actual polygon shape from the vertices found.
						var polyShape:qb2PolygonShape = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2PolygonShape();
						polyShape.set(verts, new amPoint2d(subclip.x, subclip.y), closed);
						shape = polyShape;
					}
					
					if ( shape )
					{
						object = shape;
						
						if ( userProxies ) // these are already found, so it's more optimal to just take care of them here, rather than push all the shape's children onto the queue...shapes should be the leaves in the hierarchy anyway.
						{
							for ( i = 0; i < userProxies.length; i++)
							{
								foundUserProxy(object, userProxies[i] );
							}
						}
						
						
					}
				}
				else if ( type == BODY || type == GROUP )
				{
					if ( type == BODY )
					{
						var body:qb2Body = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2Body();
						body.position.set(subclip.x, subclip.y);
						object = body;
					}
					else if( type == GROUP )
					{
						var group:qb2Group = overriddenClassName ? new (getDefinitionByName(overriddenClassName) as Class) : new qb2Group();
						object = group;
					}
					
					for ( i = 0; i < (subclip as DisplayObjectContainer).numChildren; i++ )
					{
						queue.push((subclip as DisplayObjectContainer).getChildAt(i));
					}
				}
				
				if ( object )
				{
					//--- Transform everything back to original coordinates.
					if( subclip.parent )
					{
						var parentObj:qb2Object = null;
						if ( (parentObj=objectDict[subclip.parent]) )
						{
							if ( parentObj is qb2ObjectContainer )
							{
								var parentContainer:qb2ObjectContainer = parentObj as qb2ObjectContainer;
								parentContainer.addObject(object);
								
								if ( object is qb2Tangible )
								{
									var asTang:qb2Tangible = object as qb2Tangible;
									var subclipPoint:amPoint2d = new amPoint2d(subclip.x, subclip.y);
									var localSubclipPoint:amPoint2d = parentContainer.getLocalPoint(subclipPoint);
									asTang.translateBy(localSubclipPoint.minus(subclipPoint));
									asTang.rotateBy(parentContainer.getLocalRotation(subclipRad), localSubclipPoint);
								}
							}
						}
					}
					
					objectDict[subclip] = object;
					objectDict[object]  = tags;
					proxyDict[object] = subclip;
					(subclip as qb2ProxyObject).actualObject = object;
					
					//--- Set actor for tangibles.
					if ( object is qb2Tangible )
					{
						(object as qb2Tangible).actor = subclip as qb2IActor; // this sets qb2ProxyObject::actualObject
					}
				}
			}
			
			if ( !objectDict[baseProxy] )
			{
				proxyDict = null;
				_loadingInProgress = false;
				
				return null;  // no proxies were found.
			}
			
			//--- Finish off objects by applying properties, setting actors, and letting subclasses do their thing.
			var groupActorTransforms:Dictionary = new Dictionary(true);  // stores qb2Group's->transforms.
			var queue2:Vector.<qb2Object> = new Vector.<qb2Object>();
			queue2.unshift(objectDict[baseProxy] as qb2Object);
			while ( queue2.length )
			{
				object = queue2.shift();
				
				if ( object is qb2Tangible )
				{
					popDown((object as qb2Tangible).actor as DisplayObject);
					
					asTang = object as qb2Tangible;
					
					if ( asTang is qb2IRigidObject )
					{
						var asRigid:qb2IRigidObject = asTang as qb2IRigidObject;
						//trace(asTang, asTang.actor.x);
					}
				
					if ( groupActorTransforms[object.parent] )
					{
						var matrix:Matrix = (asTang.actor as DisplayObject).transform.matrix.clone();
						matrix.concat(groupActorTransforms[asTang.parent]);
						(asTang.actor as DisplayObject).transform.matrix = matrix;
					}
				
					if ( object is qb2ObjectContainer )
					{
						var container:qb2ObjectContainer = object as qb2ObjectContainer;
						
						if ( container is qb2Group )
						{
							group = container as qb2Group;
							groupActorTransforms[group] = (group.actor as DisplayObject).transform.matrix.clone();
							(group.actor as DisplayObject).transform.matrix = new Matrix();
						}
						
						for ( i = 0; i < container.numObjects; i++ )
						{
							queue2.push(container.getObjectAt(i));
						}
					}
					
					//trace(asTang, asTang._rotation * TO_DEG , asTang.actor.rotation);
				}
				else if ( object is qb2Joint )
				{
					var asJoint:qb2Joint = object as qb2Joint;
					
					//--- Settings the joints attachments here...however if the joint doesn't have a parent (if it's the only thing we're loading), then it can't have rigids attached to it.
					if ( asJoint.parent )
					{
						var search1:qb2Tangible = null;
						var search2:qb2Tangible = null;
					
						if ( asJoint.requiresTwoRigids )
						{
							search1 = jointProxy["overrideObject1"] ? objectDict[jointProxy["overrideObject1"]] : asJoint.parent;
							search2 = jointProxy["overrideObject2"] ? objectDict[jointProxy["overrideObject2"]] : asJoint.parent;
						}
						else
						{
							search1 = jointProxy["overrideObject"] ? objectDict[jointProxy["overrideObject"]] : asJoint.parent;
						}
						
						setJointRigids(asJoint, search1, search2);
					}
				}
				
				tags = objectDict[object] as Vector.<qb2Proxy>;
				
				if ( tags )
				{
					for ( i = 0; i < tags.length; i++)
						applyTag(object, tags[i]);
				}
				
				finishObject(object);
			}
			
			var returnObject:qb2Object = objectDict[baseProxy] as qb2Object;
		
			if ( newSource is Class )
			{
				//--- Object is now cached, meaning further calls to loadObject from any qb2FlashLoader instance using the same Class as the source will be much more efficient.
				cache[newSource] = returnObject is qb2Joint ? (returnObject as qb2Joint).clone() : (returnObject as qb2Tangible).clone();
			}
			
			proxyDict = null;
			_loadingInProgress = false;
			
			return returnObject;
		}
		
		private static function setJointRigids(joint:qb2Joint, search1:qb2Tangible, search2:qb2Tangible):void
		{
			if ( joint.requiresTwoRigids )
			{
				var worldAnchor1:amPoint2d = joint._localAnchor1;
				var worldAnchor2:amPoint2d = joint._localAnchor2;
				
				var rigid1:qb2IRigidObject, rigid2:qb2IRigidObject;
				var availableRigids:Vector.<qb2IRigidObject>;
					
				if ( (search1 is qb2IRigidObject) && (search2 is qb2IRigidObject) )
				{
					rigid1 = search1 as qb2IRigidObject;
					rigid2 = search2 as qb2IRigidObject;
				}
				else if ( search1 is qb2IRigidObject )
				{
					rigid1 = search1 as qb2IRigidObject;
			
					availableRigids = (search2 as qb2ObjectContainer).getRigidsAtPoint(worldAnchor2);
					if ( availableRigids )
					{
						rigid2 = availableRigids.pop();
						while ( rigid1 == rigid2 && availableRigids.length)
						{
							rigid2 = availableRigids.pop();
						}
					}
				}
				else if ( search2 is qb2IRigidObject )
				{
					rigid2 = search2 as qb2IRigidObject;
					
					availableRigids = (search1 as qb2ObjectContainer).getRigidsAtPoint(worldAnchor1);
					if ( availableRigids )
					{
						rigid1 = availableRigids.pop();
						while ( rigid2 == rigid1 && availableRigids.length)
						{
							rigid1 = availableRigids.pop();
						}
					}
				}
				else // both objects are container objects.
				{
					if ( search1 == search2 ) // dealing with the same container object for both anchor points.
					{
						availableRigids = (search1 as qb2ObjectContainer).getRigidsAtPoint(worldAnchor1);
						
						if ( availableRigids )
						{
							rigid1 = availableRigids.pop();
							
							if ( worldAnchor1 == worldAnchor2 )
							{
								if ( availableRigids.length )
									rigid2 = availableRigids.pop();
							}
							else
							{
								availableRigids = (search1 as qb2ObjectContainer).getRigidsAtPoint(worldAnchor2);
								if ( availableRigids )
								{
									rigid2 = availableRigids.pop();
									
									while ( rigid1 == rigid2 && availableRigids.length)
									{
										rigid2 = availableRigids.pop(); // there's a chance that the first tangible found at the different world anchor could == rigid1, so pop until a different tangible is found
									}
								}
							}
						}
					}
					else // dealing with different container objects for each anchor point.
					{
						//--- Here we can limit the number of tangibles returned because there's no chance for the
						//--- same tangible to be retrieved from two different containers.
						availableRigids = (search1 as qb2ObjectContainer).getRigidsAtPoint(worldAnchor1, 1);
						if ( availableRigids )
							rigid1 = availableRigids.pop();
						availableRigids = (search2 as qb2ObjectContainer).getRigidsAtPoint(worldAnchor2, 1);
						if ( availableRigids )
							rigid2 = availableRigids.pop();
					}
				}
		
				//--- Avoid having identical ridgids.
				if ( (rigid1 || rigid2) && rigid1 == rigid2 )
				{
					if ( rigid1 )
						rigid2 = null;
					else if ( rigid2 )
					{
						rigid1 = rigid2;
						rigid2 = null;
					}
				}
				
				joint.setObject1(rigid1);
				joint.setObject2(rigid2);
			}
			else // otherwise it's a joint with one object (e.g. a mouse joint).
			{
				var worldAnchor:amPoint2d = joint._localAnchor1;
				
				var search:qb2Tangible = search1;
				
				var rigid:qb2IRigidObject;
				
				if ( search is qb2IRigidObject )
					rigid = search as qb2IRigidObject;
				else
				{
					//--- We can limit the number of tangibles returned to 1 here.
					availableRigids = (search as qb2Group).getRigidsAtPoint(worldAnchor, 1);
					if ( availableRigids )
					{
						rigid = availableRigids.pop();
					}
				}
				
				joint.setObject2(rigid);
			}
		}

		private function getTags(sprite:DisplayObject):Vector.<qb2Proxy>
		{
			var tags:Vector.<qb2Proxy> = null;
			
			if ( (sprite is DisplayObjectContainer) )
			{
				var container:DisplayObjectContainer = sprite as DisplayObjectContainer;
				for ( var i:int = 0; i < container.numChildren; i++ )
				{
					var subchild:DisplayObject = container.getChildAt(i);
					
					if ( !(subchild is qb2Proxy) )  continue;
					
					if ( containsProxyTag(subchild as qb2Proxy) )
					{
						if ( !tags )  tags = new Vector.<qb2Proxy>();
						
						container.removeChildAt(i--);
						tags.push(subchild);
					}
				}
			}
			
			return tags;
		}
		
		private static function containsProxyTag(proxy:qb2Proxy):Boolean
		{
			var numChildren:int = proxy.numChildren;
			for (var i:int = 0; i < numChildren; i++) 
			{
				var ithChild:DisplayObject = proxy.getChildAt(i);
				
				if ( ithChild is qb2ProxyTag )
				{
					return true;
				}
			}
			
			return false;
		}
		
		private static function getClassName(proxy:qb2Proxy, tags:Vector.<qb2Proxy>):String
		{
			if ( !defaultValue(proxy.className) )
				return proxy.className;
			
			if ( tags )
			{
				for (var i:int = tags.length-1; i >= 0; i--) // hit the highest z-order tags first
				{
					var tag:qb2Proxy = tags[i];
					
					if ( tag is qb2ProxyObject )
					{
						var objectTag:qb2ProxyObject = tag as qb2ProxyObject;
						
						if ( !defaultValue(objectTag.className) )
						{
							return objectTag.className;
						}
					}
				}
			}
			
			return proxy.defaultClassName;
		}
		
		private static const TRUE_STRING:String      = "true";
		private static const DEFAULT_STRING:String   = "default";
		private static const DELIMITER_STRING:String = "_";
		
		private static const FLOAT_STRING:String     = "float";
		private static const INT_STRING:String       = "uint";
		private static const UINT_STRING:String      = "int";
		private static const BOOL_STRING:String      = "bool";
		private static const HANDLER_STRING:String   = "handler";
		
		protected static function defaultValue(variable:String):Boolean
		{
			if ( !variable )  return false;
			return variable.indexOf(DEFAULT_STRING) >= 0;
		}
		
		private static const reservedVars:Object = 
		{
			"overrideObject"  : true,
			"overrideObject1" : true,
			"overrideObject2" : true,
			"componentInspectorSetting" : true // no idea what this is, but it doesn't come up in the describeType() XML
		}
		
		private static var movieClipVars:Object = { };
		private static var movieClipVarsBuilt:Boolean = false;
		
		private static function buildMovieClipVars():void
		{
			var xml:XML = describeType(new qb2Proxy());
			var list:XMLList = xml.variable;
			var listLen:int = list.length();
			for (var i:int = 0; i < listLen; i++) 
			{
				movieClipVars[list[i].@name] = true;				
			}
			
			list = xml.accessor;
			listLen = list.length();
			for ( i = 0; i < listLen; i++) 
			{
				movieClipVars[list[i].@name] = true;				
			}
			
			movieClipVarsBuilt = true;
		}

		protected virtual function foundUserProxy(host:qb2Object, proxy:qb2ProxyUserObject):void  { }
		
		private function processList(varList:Vector.<String>, object:qb2Object, tag:qb2Proxy):void
		{
			var listLen:int = varList.length;
			var tagAsObject:Object = tag;
			for (var i:int = 0; i < listLen; i++) 
			{
				var proxyVarName:String = varList[i];
				
				//--- Skip this variable if it's reserved or is defined by MovieClip or its super classes.
				if ( reservedVars[proxyVarName] || movieClipVars[proxyVarName] )  continue;
				
				if ( (tag[proxyVarName] is String) && proxyVarName.charAt(0) == DELIMITER_STRING )
				{
					if ( tag[proxyVarName] == "" || tag[proxyVarName] == DEFAULT_STRING )  continue;
					
					var split:Array = proxyVarName.split(DELIMITER_STRING);
					split.shift();
					if ( split.length != 2 )
					{
						throw new Error("Problem with variable name.");
					}
					
					var varPrefix:String = split[0];
					var varName:String   = split[1];
					
					try
					{
						if ( varPrefix == BOOL_STRING )
						{
							object[varName] = tag[proxyVarName] == TRUE_STRING;
						}
						else if ( varPrefix == UINT_STRING )
						{
							object[varName] = modifyUnsignedInt(parseInt(tag[proxyVarName]) as uint, varName);
						}
						else if ( varPrefix == INT_STRING )
						{
							object[varName] = modifySignedInt(parseInt(tag[proxyVarName]) as int, varName);
						}
						else if ( varPrefix == FLOAT_STRING )
						{
							object[varName] = modifyFloat(parseFloat(tag[proxyVarName]), varName);
						}
						else if ( varPrefix == HANDLER_STRING )
						{
							var listener:Function = (tag.parent && tag.parent[tag[proxyVarName]] ? tag.parent[tag[proxyVarName]] : tag[proxyVarName]) as Function;
							
							if ( listener != null )
							{
								object.addEventListener(varName, listener);
							}
						}
					}
					catch (err:Error)
					{
					}
				}
				else
				{
					try
					{
						var isString:Boolean = tag[proxyVarName] is String;
						if ( isString && tag[proxyVarName] && tag[proxyVarName] != DEFAULT_STRING || !isString )
						{
							object[proxyVarName] = tag[proxyVarName];
						}
					}
					catch(err:Error)
					{
						
					}
				}
			}
		}
		
		protected function modifyUnsignedInt(value:uint, variableName:String):uint
		{
			return value;
		}
		
		protected function modifySignedInt(value:int, variableName:String):int
		{
			return value;
		}
		
		protected function modifyFloat(value:Number, variableName:String):Number
		{
			return value;
		}
		
		private static const varListCache:Dictionary = new Dictionary();
		
		protected function applyTag(object:qb2Object, tag:qb2Proxy):void
		{
			var classDef:Class = (tag as Object).constructor;
			var varList:Vector.<String> = varListCache[classDef];
			
			if ( !varList )
			{
				var xmlList:XMLList = describeType(tag).variable;
				var xmlListLen:int = xmlList.length();
				varList = new Vector.<String>(xmlListLen, true);
				for (var i:int = 0; i < xmlListLen; i++) 
				{
					varList[i] = xmlList[i].@name;
				}
				
				varListCache[classDef] = varList;
			}
			else
			{
			}
			
			processList(varList, object, tag);
			//processList(xml.accessor); proxies shouldn't really have accessor's
		}
		
		protected function finishObject(object:qb2Object):void
		{
			if ( !proxyDict || !proxyDict[object] )  return;
			
			var proxy:qb2Proxy = proxyDict[object] as qb2Proxy;
			
			applyTag(object, proxy);
				
			if ( removeEmptyProxies )
			{
				var currParent:DisplayObject = proxy;
				
				while ( currParent )
				{
					var nextParent:DisplayObjectContainer = currParent.parent;
					
					if ( currParent is DisplayObjectContainer )
					{
						var asContainer:DisplayObjectContainer = currParent as DisplayObjectContainer;
						if ( asContainer.numChildren == 0 && nextParent )
						{
							nextParent.removeChild(currParent);
						}
					}
					
					currParent = nextParent;
				}
			}
		}
		
		
		
		
		
		private static const SHAPE:uint          = 0x00000001;
		private static const GROUP:uint          = 0x00000002;
		private static const BODY:uint           = 0x00000004;
		
		private static const PISTON_JOINT:uint   = 0x00000008;
		private static const REV_JOINT:uint      = 0x00000010;
		private static const DIST_JOINT:uint     = 0x00000020;
		private static const MOUSE_JOINT:uint    = 0x00000040;
		private static const WELD_JOINT:uint     = 0x00000080;
		
		private static const USER_PROXY:uint     = 0x00000100;
		private static const EDITOR_PROXY:uint   = 0x00000200;
		
		private static const JOINT:uint            = REV_JOINT | DIST_JOINT | WELD_JOINT | PISTON_JOINT | MOUSE_JOINT;
		private static const TWO_RIGID_JOINT:uint  = JOINT & ~MOUSE_JOINT;
		private static const ONE_ANCHOR_JOINT:uint = REV_JOINT | WELD_JOINT | MOUSE_JOINT;
		
		private static const RIGID:uint          = SHAPE | BODY;
		private static const TANGIBLE:uint       = RIGID | GROUP;
		private static const OBJECT:uint         = JOINT | TANGIBLE;
		
		private static function establishType(clip:DisplayObject):uint
		{
			if ( clip is qb2ProxyBody )          return BODY;
			if ( clip is qb2ProxyGroup )         return GROUP;
			if ( clip is qb2ProxyJoint )         return JOINT;
			if ( clip is qb2ProxyShape )         return SHAPE;
			if ( clip is qb2ProxyEditorObject )  return EDITOR_PROXY;
			if ( clip is qb2ProxyUserObject )    return USER_PROXY;
			
			return 0;
		}
		
		private static function establishJointType(clip:DisplayObject):uint
		{
			if ( clip is qb2ProxyDistanceJoint )  return DIST_JOINT;
			if ( clip is qb2ProxyPistonJoint )    return PISTON_JOINT;
			if ( clip is qb2ProxyRevoluteJoint )  return REV_JOINT;
			if ( clip is qb2ProxyWeldJoint )      return WELD_JOINT;
			if ( clip is qb2ProxyMouseJoint )     return MOUSE_JOINT;
			
			return 0;
		}

		//--- Transforms a display object to its parent's coordinate space. For example if you had a movie clip at (10, 10)
		//--- containing a child also at (10, 10), calling popUp(child) would put that child at (20, 20).
		protected static function popUp(clip:DisplayObject):void
		{
			if ( !clip.parent )  return;
			
			var mat:Matrix = clip.transform.matrix.clone();
			var toConcat:Matrix = clip.parent.transform.matrix;
			mat.concat(toConcat);
			clip.transform.matrix = mat;
		}
		
		protected static function popDown(clip:DisplayObject):void
		{
			if ( !clip.parent )  return;
			
			var mat:Matrix = clip.transform.matrix.clone();
			var toConcat:Matrix = clip.parent.transform.matrix.clone();
			toConcat.invert();
			mat.concat(toConcat);
			clip.transform.matrix = mat;
		}
	}
}