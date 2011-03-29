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

		public function Peer (peerID:String, nc:NetConnection, eventRecv:Rtmfp) {
			this.recvStream = new NetStream(nc, peerID);
			this.recvStream.addEventListener(NetStatusEvent.NET_STATUS, netStatusHandler);
			this.recvStream.play("media");
			
			this.recvStream.client = this;
			this.peerID = peerID;
			this.eventRecv = eventRecv;
		}

		public function receiveMessage(message:String):void {
			var channel:String = "temp";
			this.eventRecv.log("(AS) PeerID:"+this.peerID +" message:"+message +" ("+channel+")");
			this.eventRecv.onMessageRecv(peerID, message,channel);
		}

		private function netStatusHandler(event:NetStatusEvent):void{
			this.eventRecv.log("(AS) PeerID:"+this.peerID+" Status:" + event.info.code);
		}
	}

}