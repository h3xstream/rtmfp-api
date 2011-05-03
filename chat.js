
/**
 * 
 */
$(document).ready(function() {
	initialiseSwf();
});

function initialiseSwf() {
	var flashvars = {
		DEBUG:true,
		rtmfpUrl:'rtmfp://p2p.rtmfp.net/f305c7dae01d5c4767797222-af55b81ce685',
		domain:'*',
		onMessageRecvCall:   'ChatEvents.onRtmfpMessageRecv',
		onPeerIdRecvCall:    'ChatEvents.onRtmfpPeerIdRecv',
		onPeerConnectCall:   'ChatEvents.onRtmfpPeerConnect'};
	
	swfobject.embedSWF("bin/rtmfp.swf","rtmfpSwf", "0", "0", "10.0.0",
		"expressInstall.swf",flashvars);
}

function loadInviteRoom() {
	//Load hash tag parameters
	var hash = window.location.search;
	var hashes = [];
	
	var listTmp = hash.slice(hash.indexOf('?') + 1).split('&');
	for(var h in listTmp) {
	    var split = listTmp[h].split('=');
	    hashes[split[0]] = split[1];
	}
	
	if(hashes['room']) {
		ChatActions.loadRoom(hashes['room']);
	}
	
}

/**
 * 
 */
User = function (initialNickname,peerId) {
	this.peerId = peerId;
	this.nickName = initialNickname;
}

/**
 * 
 */
ChatState = function () {
	var pub = {};
	
	return pub;
}();

ChatState.isChatOwner = false;
ChatState.connected = false;

ChatState.roomTitle = "";
ChatState.roomId = "";
ChatState.listUsers = [];
ChatState.currentUser = new User("Anonymous");
ChatState.listUsers.push(ChatState.currentUser);


/**
 * Actions
 */
ChatActions = function () {
	var pub = {};
	
	function switchToRoom(roomTitle) {
		ChatState.roomTitle = roomTitle;
		$("#room_title").text(roomTitle);
		
		if(!ChatState.connected) {
			$("#section_create").hide();
			$("#section_chat").fadeIn(1500);
			
			$("#overlay").show();
			$("#dialogNickName").show();
			
			ChatState.connected = true;
		}
	}
	
	pub.createRoom = function (roomName) {
		ChatState.isChatOwner = true;
		switchToRoom(roomName);
		
		$("#txtInviteUrl").val("http://localhost/rtmfp/chat.htm?room="+ChatState.currentUser.peerId);
		$("#divInvite").show();
	};
	
	pub.loadRoom = function(roomId) {
		$("#rtmfpSwf")[0].connectToPeer(roomId);
	};
	
	pub.sendMessage = function(message) {
		var msgDetails = [];
		msgDetails['user'] = ChatState.currentUser.nickName;
		msgDetails['message'] = message;
		
		$("#rtmfpSwf")[0].send("MSG|"+$.toJSON(msgDetails));
	};
	
	pub.changeNickName = function(nickName) {
		if(!ChatState.isChatOwner) {
			$("#rtmfpSwf").send("NICK|"+nickName);
		}
		
		ChatState.currentUser.nickName = nickName;
		ChatUI.updateListUsers();
		
		$("#overlay").hide();
		$("#dialogNickName").hide();
		
		
	};
	
	pub.sendListUsers = function() {
		var listUsers = $.extend(true,[],ChatState.listUsers);
		//listUsers.push(ChatState.currentUser);
		
		$("#rtmfpSwf")[0].send("USERS|"+$.toJSON(listUsers));
	}
	
	pub.sendRoomTitle = function() {
		$("#rtmfpSwf")[0].send("ROOM|"+ChatState.roomTitle);
	}
	
	return pub;
}();

/**
 * Events
 */
ChatEvents = function () {
	var pub = {};
	
	pub.onRtmfpMessageRecv = function(peerId,message) {
		var idx = message.indexOf("|");
		
		var cmd = message.slice(0,idx);
		var data = $.evalJSON(message.slice(idx+1));
		
		console.info("(JS) New message [cmd]="+cmd+" [data]="+data);
		
		if(cmd == 'USERS') {
			ChatState.listUsers = data;
			ChatUI.updateListUsers();
		}
		else if(cmd == 'ROOM') {
			switchToRoom(data);
		}
		else if(cmd == 'MSG') {
			ChatUI.printMessage(data['user'],data['message']);
		}
	}
	
	pub.onRtmfpPeerIdRecv = function(peerId) {
		console.info("(JS) : "+peerId);
		//ChatUI.printNotice("Your peerID is :"+peerId);
		
		ChatState.currentUser.peerId = peerId;
		//console.info("(JS) : "+ChatState.currentUser.peerId);
		loadInviteRoom();
	}
	
	pub.onRtmfpPeerConnect = function(peerId) {
		//Make sure connection is established
		if(ChatState.isChatOwner) {
			$("#rtmfpSwf")[0].connectToPeer(peerId);
			ChatActions.sendRoomTitle();
			ChatActions.sendListUsers();
		}
		else {
			
		}
	}
	
	pub.onRtmfpPeerDisconnect = function(peerId) {
		console.info(peerId+" disconnected.");
	}
	
	return pub;
}();

/**
 * Change various UI elements.
 */
ChatUI = function () {
	var pub = {};
	
	pub.printMessage = function (nickname,message) {
		$("#divMessages").innerHTML += "<b>"+escapeHtml(nickname)+"</b>"+message+"<br/>";
	}
	
	pub.printNotice = function(notice) {
		$("#divMessages").innerHTML += "<i>"+escapeHtml(notice)+"</i>";
	}
	
	pub.updateListUsers = function() {
		var ul = $('ul#ulListPeers').empty();
		
		for(var user in ChatState.listUsers) {
			ul.append("<li>"+ChatState.listUsers[user].nickName+"</li>");
		}
	}
	
	return pub;
}();


function escapeHtml(someText) {
	return $('<div/>').text(someText).html();
}
