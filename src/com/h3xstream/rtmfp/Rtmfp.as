package com.h3xstream.rtmfp
{
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.events.Event;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Dictionary;
	import flash.events.NetStatusEvent;
	import flash.system.Security;
	
	/**
	 * Main class many functions are exposed to the browser.
	 */
	public class Rtmfp extends Sprite
	{
		//Config
		public var DEBUG:Boolean = true; //Debug should disable in release version (will cause error if no console object is found)
		private var rtmfpUrl:String = ""; //Should be similar to "rtmfp://p2p.rtmfp.net/API_KEY/"
		private var domain:String = "*";
		
		
		private var nc:NetConnection;
		private var sendStream:NetStream;
		
		private var peers:Dictionary = new Dictionary();
		private var myID:String;
		
		//Callbacks
		private var onMessageRecvCall:String = null;
		private var onPeerIdRecvCall:String = null;
		private var onPeerConnectCall:String = null;
		private var onPeerDisconnectCall:String = null;
		
		public function Rtmfp():void {
			try {
				//Load flashvars parameters
				var params:Object = this.loaderInfo.parameters;
				if(params['DEBUG'] !== undefined)
					DEBUG = (params['DEBUG'] == 'true');
				if(params['rtmfpUrl'] !== undefined)
					rtmfpUrl = params['rtmfpUrl'];
				if(params['domain'] !== undefined)
					domain = params['domain'];
				
				if(params['onMessageRecvCall'] !== undefined)
					onMessageRecvCall = params['onMessageRecvCall'];
				if(params['onPeerIdRecvCall'] !== undefined)
					onPeerIdRecvCall = params['onPeerIdRecvCall'];
				if(params['onPeerConnectCall'] !== undefined)
					onPeerConnectCall = params['onPeerConnectCall'];
				if(params['onPeerDisconnectCall'] !== undefined)
					onPeerDisconnectCall = params['onPeerDisconnectCall'];
				
				log("rtmfp-api version 1.0");
				
				Security.allowDomain(domain);
				initCallbacks();
				initRTMFP(rtmfpUrl);
			}
			catch (e:Error) {
				error('Could not initialise flash app.',e);
			}
		}
		
		private function initCallbacks():void {
			//Make the method available to the browser
			ExternalInterface.addCallback("connectToPeer", this.connectToPeer);
			ExternalInterface.addCallback("send", this.send);
		}
		
		private function initRTMFP(serverAddr:String):void {
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, ncStatus);
			nc.connect(serverAddr);
		}
		
		private function listen():void {
			this.sendStream = new NetStream(nc, NetStream.DIRECT_CONNECTIONS);
			this.sendStream.addEventListener(NetStatusEvent.NET_STATUS, ncStatus);
			this.sendStream.publish("media");
			
			var client:Object = new Object();
			client.onPeerConnect = function(subscriber:NetStream):Boolean {
				log("(AS) Receive connection from " + subscriber.farID);
				onPeerConnect(subscriber.farID);
				return true;
			}
			
			this.sendStream.client = client;
		}
		
		private function ncStatus(event:NetStatusEvent):void {
			log(event.info.code);
			
			switch (event.info.code) {
				case "NetConnection.Connect.Success": //Obtain ID from rtmfp server
					log("(AS) MyID:"+nc.nearID);
					this.myID = nc.nearID;
					
					jsCall(onPeerIdRecvCall,this.myID);
					
					listen();
					break;
				case "NetStream.Publish.BadName":
					error("Please check the name of the publishing stream");
					break;
				
				case "NetStream.Connect.Success": //Peer connect
					
					break;
					
				case "NetStream.Connect.Closed": //Peer disconnect
					break;
					
				case "NetStream.Play.Start":
					
					break;
			}
		}
		
		/**
		 * Get or create a peer connection.
		 * The first call will established a connection with the remote Peer.
		 * @param peerID
		 */
		public function getPeer(peerID:String):Peer {
			if (peers[peerID] == undefined) {
				peers[peerID] = new Peer(peerID, nc, this);
			}
			return peers[peerID];
		}
		
		/**
		 * 
		 * @param peerID Establish a connection with the peer
		 */
		public function connectToPeer(peerID:String):void {
			this.getPeer(peerID);
		}
		
		/**
		 * 
		 * @param message
		 */
		public function send(message:String):void {
			try {
				sendStream.send("receiveMessage", message);
			}
			catch (e:Error) {
				error('Could not send the message "'+message+'"',e);
			}
		}
		
		/**
		 * Each message received is push to the browser.
		 * @param	peerID
		 * @param	message
		 * @param	channel
		 */
		public function onMessageRecv(peerID:String, message:String):void {
			jsCall(onMessageRecvCall, peerID, message);
		}
		
		public function onPeerConnect(peerID:String):void {
			jsCall(onPeerConnectCall, peerID);
		}
		
		/**
		 * Redirect log to browser console (works in firefox (firebug) and chrome)
		 * @param message Information to log
		 */
		public function log(message:String):void {
			if (DEBUG) {
				jsCall("console.info",message);
			}
		}
		
		public function error(message:String,e:Error=null):void {
			if (DEBUG) {
				var extra:String = e!=null?"\nerrorID:"+e.errorID+"\nmessage:"+e.message+"\nstacktrace:"+e.getStackTrace():"";
				jsCall("console.error","["+message+"]"+extra);
			}
		}
		
		public function jsCall(callback:String, ... args):void { //DO NOT use logging in this method
			args.unshift(callback);
			ExternalInterface.call.apply(null, args);
		}
		
		/**
		 * Some extra escaping is need to avoid flash bug/vulnerability.
		 * @param data Parameter to escape
		 * @return
		 */
		public function escapeFix(data:String):String {
			return data.split("\\").join("\\\\");
		}
	}
}