

package com.h3xstream.rtmfp 
{
	import flash.net.NetStream;
	import flash.net.NetConnection;
	import flash.events.NetStatusEvent;
	import flash.events.AsyncErrorEvent;
	import flash.events.IOErrorEvent;
	import flash.events.StatusEvent;
	
	/**
	 * Each peer is a connection from which we listen to receive new message.
	 */
	public class Peer 
	{
		private var recvStream:NetStream = null;
		public var eventRecv:Rtmfp;
		public var peerID:String; //As documented by Adobe the "farID"
		
		public var connected:Boolean = true;

		/**
		 * 
		 * @param	peerID Id of the peer we will try to connect.
		 * @param	nc Connection handle to the rtmfp server
		 * @param	eventRecv Main class to which new events will be redirect.
		 */
		public function Peer (peerID:String, nc:NetConnection, eventRecv:Rtmfp) {
			this.recvStream = new NetStream(nc, peerID);
			this.recvStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.recvStream.play("media");
			
			this.recvStream.client = new Client(this);
			this.peerID = peerID;
			this.eventRecv = eventRecv;
		}

		private function netStatusHandler(event:NetStatusEvent):void{
			this.eventRecv.log("(AS) PeerID:" + this.peerID + " Status:" + event.info.code);
			
			switch (event.info.code) {
				case "NetStream.Play.Start": //Peer is now ready to receive message
					this.eventRecv.onPeerConnect(this.peerID );
					break;
			}
		}
		
	}
	
	

}

import com.h3xstream.rtmfp.*;

/**
 * This class is use to sandbox the method that can be call from remote.
 * The remote sender get to choose the method when calling the "NetStream.send()" method.
 */
internal class Client {
		public var peer:Peer = null;
		public function Client(peer:Peer) {
			this.peer = peer;
		}
		
		public function receiveProbeRequest():void {
			peer.eventRecv.log("(AS) Probe request from PeerID:" + peer.peerID);
			peer.eventRecv.onProbeRequest();
		}
		public function receiveProbeResponse():void {
			peer.eventRecv.log("(AS) Probe response from PeerID:" + peer.peerID);
			peer.connected = true;
		}
		
		public function receiveMessage(message:String):void {
			peer.eventRecv.log("(AS) PeerID:"+peer.peerID+" message:"+message +"");
			peer.eventRecv.onMessageRecv(peer.peerID, message);
		}
	}