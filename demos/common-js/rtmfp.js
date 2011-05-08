/**
 * Wrapper use to communicate with the hidden flash applet.
 */
Rtmfp = function(pathSwf,config,callbacks) {
	var pub = {};
	
	var idSwfObject = "rtmfp";
	var refSwfObject = null;
	
	function init() {
		$("body").append("<div id='"+idSwfObject+"'/>");
		
		var flashvars = config;
		
		//Transform function to Global callable name
		flashvars['onPeerIdRecvCall']     = Rtmfp.Callbacks.create('onPeerIdRecv',callbacks['onPeerIdRecvCall']);
		flashvars['onPeerConnectCall']    = Rtmfp.Callbacks.create('onPeerConnect',callbacks['onPeerConnectCall']);
		flashvars['onPeerDisconnectCall'] = Rtmfp.Callbacks.create('onPeerDisconnect',callbacks['onPeerDisconnectCall']);
		
		flashvars['onMessageRecvCall'] = Rtmfp.Callbacks.create('onMessageRecv',
			function(peerId,message) {
				var idx = message.indexOf("|");
				
				var cmd = message.slice(0,idx);
				var data = $.evalJSON(message.slice(idx+1)); //Unserialiaze the object
				
				callbacks['onMessageRecvCall'].call(null,peerId,cmd,data);
			}
		);
		
		swfobject.embedSWF(pathSwf,idSwfObject, "0", "0", "10.0.0",
			"expressInstall.swf",flashvars , {}, {},
			function (res) {
				if(res.success) {
					refSwfObject = document.getElementById(idSwfObject);
				}
			});
	}
	
	pub.connectToPeer = function (peerId) {
		peerId = peerId.split("\\").join("\\\\");
		refSwfObject.connectToPeer(peerId);
	}
	
	pub.send = function(command,object) {
		var data = $.toJSON(object); //Serialiaze the object
		
		command = command.split("\\").join("\\\\");
		data = data.split("\\").join("\\\\");
		
		refSwfObject.send(command+"|"+data);
	}
	
	init()
	
	return pub;
}

Rtmfp.Callbacks = function() {
	var pub = {};
	
	/**
	 * Wrap the function in another one wich is store in the "Rtmfp.Callbacks" scope.
	 */
	pub.create = function(methodName,funct) {
		Rtmfp.Callbacks[methodName] = function() {
			return funct.apply(null, arguments);
		};
		return 'Rtmfp.Callbacks.'+methodName;
	}
	
	return pub;
}();