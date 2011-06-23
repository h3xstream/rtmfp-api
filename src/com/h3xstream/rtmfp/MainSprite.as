package com.h3xstream.rtmfp
{
	import flash.display.Sprite;
	//import flash.external.ExternalInterface;
	import flash.system.Security;
	
	/**
	 * Main class initialize the different classes.
	 */
	public class MainSprite extends Sprite
	{
		
		private var rtmfpUrl:String = ""; //Should be similar to "rtmfp://p2p.rtmfp.net/API_KEY/"
		private var domain:String = "*";
		
		private var rtmfp:RtmfpConnection = null;
		
		public function MainSprite():void {
			try {
				//Load flashvars parameters
				var params:Object = this.loaderInfo.parameters;
				if(params['DEBUG'] !== undefined)
					Logger.DEBUG = (params['DEBUG'] == 'true');
				if(params['rtmfpUrl'] !== undefined)
					rtmfpUrl = params['rtmfpUrl'];
				
				this.rtmfp = new RtmfpConnection();
				
				if(params['onMessageRecvCall'] !== undefined)
					rtmfp.onMessageRecvCall = params['onMessageRecvCall'];
				if(params['onPeerIdRecvCall'] !== undefined)
					rtmfp.onPeerIdRecvCall = params['onPeerIdRecvCall'];
				if(params['onPeerConnectCall'] !== undefined)
					rtmfp.onPeerConnectCall = params['onPeerConnectCall'];
				if(params['onPeerDisconnectCall'] !== undefined)
					rtmfp.onPeerDisconnectCall = params['onPeerDisconnectCall'];
				
				Logger.log("rtmfp-api version 1.0");
				
				Security.allowDomain(domain);
				
				rtmfp.initServerConn(rtmfpUrl);
				
				initCallbacks();
				
			}
			catch (e:Error) {
				Logger.error('Could not initialise flash app.',e);
			}
		}
		
		private function initCallbacks():void {
			//Make the method available to the browser (Incoming calls)
			Browser.addCallback("connectToPeer", rtmfp.connectToPeer);
			Browser.addCallback("send", rtmfp.send);
		}
		
		
		
		
	}
}