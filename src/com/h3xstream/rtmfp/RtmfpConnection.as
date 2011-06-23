package com.h3xstream.rtmfp 
{
	import flash.net.NetConnection;
	import flash.net.NetStream;
	
	import flash.utils.Timer;
	import flash.utils.Dictionary;
	
	import flash.events.Event;
	import flash.events.NetStatusEvent;
	import flash.events.TimerEvent;
	
	/**
	 * This class handle the initial communication with RTMFP server.
	 * It listen for incoming connection. (Connections that come from other peer.)
	 * 
	 * It will create a new Peer instance for every new connection. And keeps a list of 
	 * all the peers connected to (peers:Dictionary).
	 * 
	 * Disconnect event those not specify which peerId is consern (at least from my knowledge).
	 * When a "NetStream.Connect.Closed" is trigger, a probe is send to all the peers to confirm
	 * their state. See the two probe method in the Peer class.
	 */
	public class RtmfpConnection 
	{
		private var nc:NetConnection;
		private var sendStream:NetStream;
		
		private var peers:Dictionary = new Dictionary();
		private var myID:String;
		
		private var timerWaitForProbeResp:Timer;
		private var timerStarted:Boolean = false;
		private var timerDelay:int = 2000;
		
		//Callbacks
		public var onMessageRecvCall:String = null;
		public var onPeerIdRecvCall:String = null;
		public var onPeerConnectCall:String = null;
		public var onPeerDisconnectCall:String = null;
		
		public function RtmfpConnection() 
		{
			
		}
		
		/**
		 * Establish connection to the RTMFP server.
		 * The connection should result in the reception of "NetConnection.Connect.Success"
		 * and a peer id.
		 * @param	serverAddr Rtmfp url (rtmfp://...)
		 */
		public function initServerConn(serverAddr:String):void {
			
			nc = new NetConnection();
			nc.addEventListener(NetStatusEvent.NET_STATUS, netConnectionStatus);
			nc.connect(serverAddr);
			
			timerWaitForProbeResp = new Timer(timerDelay, 1);
			timerWaitForProbeResp.addEventListener(TimerEvent.TIMER, cleanUpPeerList);
		}
		
		/**
		 * Listen for incomming connection.
		 */
		public function listen():void {
			this.sendStream = new NetStream(nc, NetStream.DIRECT_CONNECTIONS);
			this.sendStream.addEventListener(NetStatusEvent.NET_STATUS, netConnectionStatus);
			this.sendStream.publish("media");
			
			var client:Object = new Object();
			client.onPeerConnect = function(subscriber:NetStream):Boolean {
				Logger.log("(AS) Receive connection from " + subscriber.farID);
				var resp:Boolean = onPeerConnect(subscriber.farID);
				
				
				return resp;
			}
			
			this.sendStream.client = client;
		}
		
		/**
		 * @param event Event related to the connection with rtmfp server (initServerConn method)
		 *   and related with the stream use to send messages to others (listen method)
		 */
		private function netConnectionStatus(event:NetStatusEvent):void {
			
			Logger.log("NC code="+event.info.code);
			
			switch (event.info.code) {
				case "NetConnection.Connect.Success": //Obtain ID from rtmfp server
					Logger.log("(AS) MyID:"+nc.nearID);
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
					Logger.error("Please check the name of the publishing stream");
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
			Logger.log("Connecting to "+peerID);
			this.getPeer(peerID);
		}
		
		/**
		 * Publish a message to whoever is listening.
		 * @param message
		 */
		public function send(message:String):void {
			try {
				sendStream.send("receiveMessage", message);
			}
			catch (e:Error) {
				Logger.error('Could not send the message "'+message+'"',e);
			}
		}
		
		
		
		public function onPeerIdRecv(myID:String):void {
			Browser.jsCall(onPeerIdRecvCall, this.myID);
		}
		
		/**
		 * Each message received is push to the browser.
		 * @param	peerID Source of the message
		 * @param	message Content
		 */
		public function onMessageRecv(peerID:String, message:String):void {
			Browser.jsCall(onMessageRecvCall, peerID, message);
		}
		
		public function onPeerConnect(peerID:String):* {
			var resp:* = Browser.jsCall(onPeerConnectCall, peerID);
			if (resp is Boolean) {
				Logger.log("Incoming connection from ["+peerID+"] "+(resp?"accepted":"refused"));
				return resp;
			}
			return true;
		}
		
		public function onPeerDisconnect(peerID:String):void {
			Browser.jsCall(onPeerDisconnectCall, peerID);
		}
		
	}

}