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

package TopDown.objects 
{
	import As3Math.geo2d.*;
	import flash.display.Graphics;
	import flash.events.Event;
	import flash.utils.*;
	import QuickB2.events.qb2AddRemoveEvent;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.*;
	import TopDown.ai.*;
	import TopDown.debugging.tdDebugDrawSettings;
	import TopDown.events.tdTrackEvent;
	import TopDown.internals.*;
	
	import TopDown.td_friend;
	use namespace td_friend;
	
	/**
	 * ...
	 * @author Doug Koellmer
	 */
	public class tdMap extends qb2Group
	{
		private const trackDict:Dictionary = new Dictionary(true);
		
		public function tdMap():void
		{
		}
		
		public function get trafficManager():tdTrafficManager
			{  return _trafficManager;  }
		public function set trafficManager(manager:tdTrafficManager):void
		{
			if ( _trafficManager )  _trafficManager.setMap(null);
			_trafficManager = manager;
			_trafficManager.setMap(this);
		}
		private var _trafficManager:tdTrafficManager;
		
		protected override function update():void
		{
			super.update();
			
			if ( _trafficManager )  _trafficManager.relay_update();
		}
		
		protected override function justAddedObject(object:qb2Object):void
		{
			if ( object is tdTrack )
			{
				var track:tdTrack = object as tdTrack;
				track._map = this;
				
				trackDict[track] = true;
				
				updateTrackBranches(track);
			}
			else if ( object is tdTerrain )
			{
				var terrain:tdTerrain = object as tdTerrain;
				
				if ( terrain.ubiquitous )
				{
					ubiquitousTerrain = terrain;
				}
			}
		}
		
		td_friend var ubiquitousTerrain:tdTerrain;
		
		protected override function justRemovedObject(object:qb2Object):void
		{
			if ( object is tdTrack )
			{
				var track:tdTrack = object as tdTrack;
				track.clearBranches();
				track._map = null;
				
				delete trackDict[track];
			}
			else if ( object is tdTerrain )
			{
				var terrain:tdTerrain = object as tdTerrain;
				
				if ( terrain.ubiquitous )
				{
					ubiquitousTerrain = null;
				}
			}
		}
		
		td_friend function updateTrackBranches(track:tdTrack):void
		{
			if ( !trackDict[track] )  return;
			
			track.clearBranches();
			
			for ( var key:* in trackDict ) 
			{
				var ithTrack:tdTrack = key as tdTrack;
				
				var trackLine:amLine2d = track.lineRep;
				var ithTrackLine:amLine2d = ithTrack.lineRep;
				
				var intPoint:amPoint2d = new amPoint2d();
				if ( trackLine.intersectsLine(ithTrackLine, intPoint) )
				{
					//--- Add the ith track to the input track's branches.
					var trackBranch:tdInternalTrackBranch = new tdInternalTrackBranch();
					trackBranch.track = ithTrack;
					trackBranch.distance = trackLine.getDistAtPoint(intPoint);
					track.addBranch(trackBranch);
					
					//--- Add the input track to the ith track's branches.
					trackBranch = new tdInternalTrackBranch();
					trackBranch.track = track;
					trackBranch.distance = ithTrackLine.getDistAtPoint(intPoint);
					ithTrack.addBranch(trackBranch);
				}
			}
		}

		public override function drawDebug(graphics:Graphics):void
		{
			super.drawDebug(graphics);
		}
	}
}