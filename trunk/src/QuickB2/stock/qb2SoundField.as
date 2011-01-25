package QuickB2.stock 
{
	import As3Math.general.amUtils;
	import flash.utils.Dictionary;
	import QuickB2.debugging.qb2_debugDrawSettings;
	import QuickB2.events.qb2ContainerEvent;
	import QuickB2.events.qb2ContactEvent;
	import QuickB2.objects.qb2Object;
	import QuickB2.objects.tangibles.qb2Body;
	import QuickB2.objects.tangibles.qb2ObjectContainer;
	import QuickB2.objects.tangibles.qb2Shape;
	import QuickB2.objects.tangibles.qb2Tangible;
	import SoundTree.objects.stSoundObject;
	
	public class qb2SoundField extends qb2Body
	{
		public var ignoreList:Array = null;
		
		public function qb2SoundField() 
		{
			addEventListener(qb2ContainerEvent.ADDED_TO_WORLD, addedOrRemoved, false, 0, true);
			addEventListener(qb2ContainerEvent.REMOVED_FROM_WORLD, addedOrRemoved, false, 0, true);
			addEventListener(qb2ContactEvent.CONTACT_STARTED, contact, false, 0, true);
			addEventListener(qb2ContactEvent.CONTACT_ENDED, contact, false, 0, true);
		}
		
		private function addedOrRemoved(evt:qb2ContainerEvent):void
		{
			if ( evt.type == qb2ContainerEvent.ADDED_TO_WORLD )
			{
				globalSoundFieldList.unshift(evt.childObject);
			}
			else
			{
				globalSoundFieldList.splice(globalSoundFieldList.indexOf(this), 1);
			}
		}
		
		public static var ear:qb2Tangible = null;
		
		private static var globalSoundFieldList:Vector.<qb2SoundField> = new Vector.<qb2SoundField>();
		private static var soundDict:Dictionary = new Dictionary(true);
		
		public function get sound():stSoundObject
			{  return _sound;  }
		public function set sound(object:stSoundObject):void
		{
			if ( _sound )
			{
				var array:Vector.<qb2SoundField> = soundDict[_sound];
				array.splice(array.indexOf(this), 1);
				if ( !array.length )
				{
					delete soundDict[_sound];
					_sound.stop();
				}
			}
			
			_sound = object;
			
			if ( _sound )
			{
				if ( !soundDict[_sound] )
				{
					array = new Vector.<qb2SoundField>();
					array.push(this);
					soundDict[_sound] = array;
				}
			}
		}
		private var _sound:stSoundObject;
		
		protected override function update():void
		{
			super.update();
			
			if ( !ear )  return;
			
			//--- We can only update sound volumes when the last sound field is updated.
			if ( this == globalSoundFieldList[globalSoundFieldList.length - 1] )
			{
				updateVolumes();
			}
		}
		
		private static function updateVolumes():void
		{
			var soundVolumeDict:Dictionary = new Dictionary(true);
			var soundNumDict:Dictionary = new Dictionary(true);
			
			for (var i:int = 0; i < globalSoundFieldList.length; i++) 
			{
				var soundField:qb2SoundField = globalSoundFieldList[i];
				
				if ( !soundField._sound )  continue;
				
				var continueToNext:Boolean = false;
				var ignores:Array = soundField.ignoreList;
				for (var j:int = 0; j < ignores.length; j++) 
				{
					var ignore:* = ignores[j];
					
					if ( ignore is Class )
					{
						var asClass:Class = ignore as Class;
						if ( ear is asClass )
						{
							continueToNext = true;
						}
					}
					else if ( ignore == ear )
					{
						continueToNext = true;
					}
				}
				
				if ( continueToNext )  continue;

				var soundField_inContactWithEar:Boolean = false;
				for (var key:* in soundField.shapeContactList ) 
				{
					var shape:qb2Shape = key as qb2Shape;
					
					if ( shape == ear )
					{
						soundField_inContactWithEar = true;
						break;
					}
					else if ( ear is qb2ObjectContainer )
					{
						if ( shape.isDescendantOf(ear as qb2ObjectContainer) )
						{
							soundField_inContactWithEar = true;
							break;
						}
					}
				}
				
				if ( !soundField_inContactWithEar )
				{
					continue;
				}
				
				var volume:Number = 1;
				
				if ( soundField._horizonTang )
				{
					var distance:Number = soundField.distanceTo(ear, null, null, null, soundField._horizonTang);
					volume = 1-amUtils.constrain(distance / soundField._horizon, 0, 1);
				}
				
				if ( !soundVolumeDict[soundField._sound] )
				{
					soundVolumeDict[soundField._sound] = 0.0 as Number;
					soundNumDict[soundField._sound] = 0 as int;
				}
				
				soundVolumeDict[soundField._sound] += volume;
				soundNumDict[soundField._sound]++;
			}
			
			for ( key in soundDict )
			{
				var sound:stSoundObject = key as stSoundObject;
				
				if ( soundNumDict[sound] )
				{
					var numberOfSounds:Number = soundNumDict[key];
					var soundVolume:Number = soundVolumeDict[key];
					
					sound.volume = soundVolume / numberOfSounds;
					
					if ( !sound.playing )
					{
						sound.play();
					}
				}
				else
				{
					if ( sound.playing )
					{
						sound.stop();
					}
				}
			}
		}
		
		private function contact(evt:qb2ContactEvent):void
		{
			var otherShape:qb2Shape = evt.otherShape;
			
			if ( evt.type == qb2ContactEvent.CONTACT_STARTED )
			{
				if ( !shapeContactList[otherShape] )
				{
					shapeContactList[otherShape] = 0 as int;
				}
				
				shapeContactList[otherShape]++;
			}
			else
			{
				shapeContactList[otherShape]--;
				
				if ( shapeContactList[otherShape] == 0 ) 
				{
					delete shapeContactList[otherShape];
				}
			}
		}
		private var shapeContactList:Dictionary = new Dictionary(true);
		
		public function get horizon():Number
			{  return _horizon;  }
		public function set horizon(value:Number):void
		{
			_horizon = value;
			
			refreshHorizonTang();
		}
		private var _horizon:Number = 0;
		
		private function refreshHorizonTang():void
		{
			if ( _horizonTang )
			{
				removeObject(_horizonTang);
				_horizonTang = null;
			}
			
			if ( _horizon > 0 )
			{
				_horizonTang = makeHorizonTang();
				addObject(_horizonTang);
			}
		}
		private var _horizonTang:qb2Tangible = null;
		
		protected function makeHorizonTang():qb2Tangible
		{
			return null;
		}
		
		public override function drawDebug(graphics:Graphics):void
		{
			debugFillColorStack.unshift(qb2_debugDrawSettings.soundFieldFillColor);
				super.drawDebug(graphics);
			debugFillColorStack.shift();
		}
		
		public override function clone():qb2Object
		{
			var clone:qb2SoundField = super.clone() as qb2SoundField;
			
			clone._horizon = this._horizon; // don't use setter, cause horizonTang gets made through the clone.
			clone.sound = this.sound;
			
			if ( !ignoreList )  return clone;
			
			clone.ignoreList = [];
			
			for (var i:int = 0; i < ignoreList.length; i++) 
			{
				clone.ignoreList.push(ignoreList[i]);
			}
			
			return clone;
		}
	}
}