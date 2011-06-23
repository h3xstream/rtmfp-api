package com.h3xstream.rtmfp 
{
	import flash.external.ExternalInterface;
	
	/**
	 * This class wrap the interaction with the browser.
	 * Additionnal escaping is done when calling Javascript function due to a 
	 * flash vulnerability that can lead to XSS exploitation.
	 */
	public class Browser 
	{
		/**
		 * Call a Javascript function load in the broswer.
		 * 
		 * @param	callback
		 * @param	... args
		 * @return Result of the function call
		 */
		public static function jsCall(callback:String, ... args):* {
			//DO NOT use logging in this method (to avoid recursive call)
			for (var arg:String in args) {
				arg = escapeFix(arg);
			}
			args.unshift(callback);
			return ExternalInterface.call.apply(null, args);
		}
		
		/**
		 * Some extra escaping is need to avoid flash bug/vulnerability.
		 * @param data Parameter to escape
		 * @return
		 */
		private static function escapeFix(data:String):String {
			return data.split("\\").join("\\\\");
		}
		
		public static function addCallback(functionName:String,closure:Function):void {
			ExternalInterface.addCallback(functionName,closure);
		}
	}

}