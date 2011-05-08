package com.h3xstream.rtmfp
{
	import flash.display.Sprite;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import flash.utils.Timer;
	import flash.utils.Dictionary;
	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	
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
		
		private var timerWaitForProbeResp:Timer;
		private var timerStarted:Boolean = false;
		private var timerDelay:int = 2000;
		
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
				
				timerWaitForProbeResp = new Timer(timerDelay, 1);
				timerWaitForProbeResp.addEventListener(TimerEvent.TIMER, cleanUpPeerList);
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
			nc.addEventListener(NetStatusEvent.NET_STATUS, netConnectionStatus);
			nc.connect(serverAddr);
		}
		
		private function listen():void {
			this.sendStream = new NetStream(nc, NetStream.DIRECT_CONNECTIONS);
			this.sendStream.addEventListener(NetStatusEvent.NET_STATUS, netConnectionStatus);
			this.sendStream.publish("media");
			
			var client:Object = new Object();
			client.onPeerConnect = function(subscriber:NetStream):Boolean {
				log("(AS) Receive connection from " + subscriber.farID);
				var resp:Boolean = onPeerConnect(subscriber.farID);
				
				
				return resp;
			}
			
			this.sendStream.client = client;
		}
		
		/**
		 * @param event Event related to the connection with rtmfp server (initRTMFP method)
		 *   and related with the stream use to send messages to others (listen method)
		 */
		private function netConnectionStatus(event:NetStatusEvent):void {
			
			log("NC code="+event.info.code);
			
			switch (event.info.code) {
				case "NetConnection.Connect.Success": //Obtain ID from rtmfp server
					log("(AS) MyID:"+nc.nearID);
					this.myID = nc.nearID;
					
					onPeerIdRecv(this.myID);
					
					listen();
					break;
					
				case "NetStream.Connect.Success": //Peer connect
					
					break;	
				
				case "NetStream.Connect.Closed": //Peer disconnect
					if (timerStarted == false) {
						timerStarted = true;
						//Set every peer to disconnect
						for (var p:String in peers) {
							peers[p].connected = false;
						}
						//Send the probe
						sendStream.send("receiveProbeRequest");
						//Wait
						timerWaitForProbeResp.start();
					}
					
					break;
					
				case "NetStream.Publish.BadName":
					error("Please check the name of the publishing stream");
					break;
			}
		}
		
		
		public function onProbeRequest():void {
			//log("Receive probe ...and replying")
			sendStream.send("receiveProbeResponse");
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
		
		private function cleanUpPeerList(event:TimerEvent):void {
			for (var p:String in peers) {
				if (peers[p].connected == false) {
					//Probe not receive for this peer
					onPeerDisconnect(peers[p].peerID);
				}
				else {
					//Probe receive for this peer
				}
			}
			timerStarted = false;
		}
		
		/**
		 * 
		 * @param peerID Establish a connection with the peer
		 */
		public function connectToPeer(peerID:String):void {
			log("Connecting to "+peerID);
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
		
		public function onPeerIdRecv(myID:String):void {
			jsCall(onPeerIdRecvCall, this.myID);
		}
		
		/**
		 * Each message received is push to the browser.
		 * @param	peerID Source of the message
		 * @param	message Content
		 */
		public function onMessageRecv(peerID:String, message:String):void {
			jsCall(onMessageRecvCall, peerID, message);
		}
		
		public function onPeerConnect(peerID:String):* {
			var resp:* = jsCall(onPeerConnectCall, peerID);
			if (resp is Boolean) {
				log("Incoming connection from ["+peerID+"] "+(resp?"accepted":"refused"));
				return resp;
			}
			return true;
		}
		
		public function onPeerDisconnect(peerID:String):void {
			jsCall(onPeerDisconnectCall, peerID);
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
		
		public function jsCall(callback:String, ... args):* { //DO NOT use logging in this method
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
		public function escapeFix(data:String):String {
			return data.split("\\").join("\\\\");
		}
	}
}