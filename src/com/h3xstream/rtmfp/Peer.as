package com.h3xstream.rtmfp 
{
	import flash.net.NetStream;
	import flash.net.NetConnection;
	import flash.events.NetStatusEvent;
	
	/**
	 * Each peer is a connection from which we listen to receive new message.
	 */
	public class Peer 
	{
		private var recvStream:NetStream = null;
		private var eventRecv:Rtmfp;
		private var peerID:String; //As documented by Adobe the "farID"

		private var isInit:Boolean = false;

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
			
			this.recvStream.client = this;
			this.peerID = peerID;
			this.eventRecv = eventRecv;
		}

		public function receiveMessage(message:String):void {
			this.eventRecv.log("(AS) PeerID:"+this.peerID +" message:"+message +"");
			this.eventRecv.onMessageRecv(peerID, message);
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