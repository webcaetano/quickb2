package
{
    import flash.events.Event;
	import flash.events.EventDispatcher;
    import flash.events.IOErrorEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.URLLoader;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.text.StyleSheet;
    
    [Event(name="sourceLoaded", type="flash.events.Event")]
    [Event(name="badResponse", type="flash.events.Event")]
    [Event(name="ioError", type="flash.events.IOErrorEvent")]
    [Event(name = "securityError", type = "flash.events.SecurityErrorEvent")]
	
    public class GeshiThing extends EventDispatcher
	{
        public static const SOURCE_LOADED:String = "sourceLoaded";
        public static const BAD_RESPONSE:String = "badResponse";
        
        private var _serviceUrl:String = "http://quickb2.dougkoellmer.com/geshiservice.php"
        private var _source:String;
        private var _language:String = "actionscript3";
        
        public function GeshiThing(sourceCode:String)
		{
			_source = sourceCode;
			
           urlLoader = new URLLoader();
            var urlRequest:URLRequest = new URLRequest(_serviceUrl);
            urlRequest.method = URLRequestMethod.POST;
            var data:URLVariables = new URLVariables();
            data.source = _source;
            data.language = _language;
            urlRequest.data = data;
            urlLoader.addEventListener(Event.COMPLETE, sourceLoadedHandler, false, 0, true);
            urlLoader.addEventListener(IOErrorEvent.IO_ERROR, bubbleEventHandler, false, 0, true);
            urlLoader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, bubbleEventHandler, false, 0, true);
            urlLoader.load(urlRequest);
        }
		
		public var htmlText:String;
		public var styleSheet:StyleSheet;
        private var urlLoader:URLLoader;
		
        private function sourceLoadedHandler(event:Event):void
		{
			
            var geshiXml:XML;
            try {
                geshiXml = new XML(urlLoader.data);
                htmlText = geshiXml.source;
                
                if (styleSheet) {
                    styleSheet.clear();
                    styleSheet = null;
                  //  validateNow();
                }
                
                var css:String = geshiXml.styles;
                var stylesSlit:Array = css.split("." + _language + " ");
                css = stylesSlit.join("");
                css += " a:hover { text-decoration: underline; } ";
                
                var newStyleSheet:StyleSheet = new StyleSheet();
                newStyleSheet.parseCSS(css);
                styleSheet = newStyleSheet;
                
                dispatchEvent(new Event(SOURCE_LOADED));
            } catch (e:Error) {
                dispatchEvent(new Event(BAD_RESPONSE));
            }
			
			releaseListeners();
        }
        
        private function bubbleEventHandler(event:Event):void
		{
            //dispatchEvent(event);
			releaseListeners();
        }
		
		public function releaseListeners():void
		{
			urlLoader.removeEventListener(Event.COMPLETE, sourceLoadedHandler);
            urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, bubbleEventHandler);
            urlLoader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, bubbleEventHandler);
		}
    }
}