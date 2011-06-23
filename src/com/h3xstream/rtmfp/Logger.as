package com.h3xstream.rtmfp 
{
	/**
	 * trace() could have been use to debug the flash app.
	 * Instead console.info() method is trigger to integrate nicely Chrome and Firefox (Firebug).
	 */
	public class Logger 
	{
		//Debug should disable in release version (can be override at runtime via flashvars)
		public static var DEBUG:Boolean = true;
		
		/**
		 * Redirect log to browser console (works in firefox (firebug) and chrome)
		 * @param message Information to log
		 */
		public static function log(message:String):void {
			if (DEBUG) {
				Browser.jsCall("console.info",message);
			}
		}
		
		public static function error(message:String,e:Error=null):void {
			if (DEBUG) {
				var extra:String = e!=null?"\nerrorID:"+e.errorID+"\nmessage:"+e.message+"\nstacktrace:"+e.getStackTrace():"";
				Browser.jsCall("console.error","["+message+"]"+extra);
			}
		}
	}

}