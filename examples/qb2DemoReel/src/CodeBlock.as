package  
{
	import com.bit101.components.*;
	import com.greensock.events.*;
	import com.greensock.loading.*;
	import flash.events.*;
	import flash.text.*;
	
	public class CodeBlock extends TextArea
	{		
		public function CodeBlock(address:String)
		{
			//html = true;
			_panel.color = 0xffffff;
			_tf.backgroundColor = 0xcccccc;
			_tf.antiAliasType = AntiAliasType.ADVANCED;
			
			this.width = Main.singleton.stage.stageWidth;
			this.height = Main.singleton.stage.stageHeight - 20;
			
			setSourceText(address);
			
			y = 20;
		}
		
		public function setSourceText(address:String):void
		{
			if ( _geshi )
			{
				_geshi.removeEventListener(GeshiThing.SOURCE_LOADED, prettified);
				_geshi.releaseListeners();
				_geshi = null;
			}
			
			
			
			if ( !address )
			{
				return;
			}
			
			var dataLoader:DataLoader = new DataLoader(address);
			dataLoader.addEventListener(LoaderEvent.COMPLETE, completed);
			dataLoader.addEventListener(LoaderEvent.IO_ERROR, ioError);
			dataLoader.load();
			
			//this._tf.styleSheet = null;
		}
		
		private function ioError(evt:Event):void
		{
			// this is just here to prevent erros from popping up
		}
		
		private var _geshi:GeshiThing;
		
		private function completed(evt:Event):void
		{
			selectable = false;
			editable = false;
			
			var dataLoader:DataLoader = evt.currentTarget as DataLoader;
			dataLoader.removeEventListener(LoaderEvent.COMPLETE, completed);
			
			var string:String = dataLoader.content as String;
			string = string.split("\n").join("");
			
			_tf.textColor = 0;;
			html = false;
			this.text = string; // display raw text until geshi thing gets back to us, if ever.
			
			_geshi = new GeshiThing(string);
			_geshi.addEventListener(GeshiThing.SOURCE_LOADED, prettified);
		}
		
		private function prettified(evt:Event):void
		{
			_geshi.removeEventListener(GeshiThing.SOURCE_LOADED, prettified);
			
			//html = true;
			this._tf.styleSheet = _geshi.styleSheet;
			this._tf.htmlText = _geshi.htmlText;
			//this.draw();
		}
		
		public override function draw():void
		{
			var ss:StyleSheet = this._tf.styleSheet;
			this._tf.styleSheet = null;
			
			super.draw();
			
			this._tf.styleSheet = ss;
		}
		
		protected override function onMouseWheel(event:MouseEvent):void
		{
			super.onMouseWheel(event);
			_tf.scrollV = Math.round(_scrollbar.value);
		}
	}
}