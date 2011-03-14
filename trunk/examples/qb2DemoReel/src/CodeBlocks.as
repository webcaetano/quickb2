package  
{
	import com.bit101.components.*;
	import flash.display.*;
	import flash.events.*;
	import flash.text.StyleSheet;
	
	public class CodeBlocks extends Sprite
	{
		public static var singleton:CodeBlocks;
		
		private var demoSource:CodeBlock;
		
		[Embed(source="../lib/Cour.ttf", embedAsCFF="false", fontName="Courier New", mimeType="application/x-font")]
		protected var Courier:Class;
		
		private var defaultSize:Number = Style.fontSize;
		private var defaultName:String = Style.fontName;
		private var defaultInputColor:uint = Style.INPUT_TEXT;
		private var defaultLabelColor:uint = Style.LABEL_TEXT;
		
		private var _blocks:Vector.<CodeBlock> = new Vector.<CodeBlock>();
		private var _buttons:Vector.<PushButton> = new Vector.<PushButton>();
		
		private static const FADE_ALPHA:Number = .5;
		
		public function CodeBlocks() 
		{
			singleton = this;
			
			//--- Make two special code blocks for Main and Demo.
			addBlock("../src/Main.as");
			addBlock("../src/demos/Demo.as");
		}
		
		public function addBlock(path:String):void
		{
			darkenButtons();
			
			switchToCourierFont();
			
			//--- Make a new block of code.
			var block:CodeBlock = new CodeBlock(path);
			if ( _blocks.length )
			{
				var lastBlock:CodeBlock = _blocks[i];
				block.y = lastBlock.y;
				block.width = lastBlock.width;
			}
			_currentBlock = block;
			_blocks.push(block);
			addChild(block);
			
			//--- Find where the next tab should go.
			var newX:Number = 0;
			for (var i:int = 0; i < _buttons.length; i++) 
			{
				newX += _buttons[i].width;
			}
			
			if ( _buttons.length >= 2 )
			{
				newX += 5;
			}
			
			switchToDefaultFont();
			
			//--- Add the tab.
			var chunks:Array = path.split("/");
			var fileName:String = chunks[chunks.length - 1];
			var butt:PushButton = new PushButton(this, newX, 0, fileName, buttonPressed);
			butt.width = (butt.getChildAt(2) as Label).textField.textWidth + 10;  // a bad hack, i know.
			butt.toggle = true;
			_buttons.push(butt);
			
			block.y = butt.height;
		}
		
		private function switchToCourierFont():void
		{
			Style.fontSize = 13;
			Style.fontName = "Courier New";
			Style.INPUT_TEXT = 0;
			Style.LABEL_TEXT = 0;
		}
		
		private function switchToDefaultFont():void
		{
			Style.fontSize = defaultSize;
			Style.fontName = defaultName;
			Style.INPUT_TEXT = defaultInputColor;
			Style.LABEL_TEXT = defaultLabelColor;
		}
		
		private function darkenButtons():void
		{
			for (var i:int = 0; i < _buttons.length; i++) 
			{
				dehighlightBlock(i);
			}
		}
		
		public function highlightTab(name:String):void
		{
			for (var i:int = 0; i < _buttons.length; i++) 
			{
				var butt:PushButton = _buttons[i];
				if ( butt.label == name )
				{
					highlightBlock(i);
					
				}
				else
				{
					dehighlightBlock(i);
				}
			}
		}
		
		private function highlightBlock(index:uint):void
		{
			_buttons[index].alpha = 1;
			_buttons[index].selected = true;
			_blocks[index].visible = true;
			_currentBlock = _blocks[index];
		}
		
		public function get currentBlock():CodeBlock
		{
			return _currentBlock;
		}
		private var _currentBlock:CodeBlock = null;
		
		private function dehighlightBlock(index:uint):void
		{
			_buttons[index].alpha = FADE_ALPHA;
			_buttons[index].selected = false;
			_blocks[index].visible = false;
		}
		
		private function buttonPressed(evt:Event):void
		{
			for (var i:int = 0; i < _buttons.length; i++) 
			{
				var butt:PushButton = _buttons[i];
				if ( butt == evt.currentTarget )
				{
					highlightBlock(i);
					
					if ( butt.label != "Demo.as" && butt.label != "Main.as" )
					{
						//--- Minus two because Main and demo take up first two code blocks.
						Main.singleton.switchDemo(i-2, false);
					}
				}
				else
				{
					dehighlightBlock(i);
				}
			}
		}
		
		public function resize(resizeWidth:Number, resizeHeight:Number):void
		{
			for (var i:int = 0; i < _blocks.length; i++) 
			{
				var block:CodeBlock = _blocks[i];
				block.width = resizeWidth;
				block.height = resizeHeight - 20; // minus 60 is for the window header times 3
			}
		}
	}
}