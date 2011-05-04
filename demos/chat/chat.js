
var url_params = loadQueryParams();
var rtmfp = null;

/**
 * 
 */
$(document).ready(function() {
	initialiseRtmfp();
	
	if(url_params['room']) {
		$("#overlay").show();
		$("#divDialogConnect").show();
	}
});

function initialiseRtmfp() {
	var config = {
		DEBUG:false,
		rtmfpUrl:'rtmfp://p2p.rtmfp.net/f305c7dae01d5c4767797222-af55b81ce685',
		domain:'*',
		onMessageRecvCall:   'ChatEvents.onRtmfpMessageRecv',
		onPeerIdRecvCall:    'ChatEvents.onRtmfpPeerIdRecv',
		onPeerConnectCall:   'ChatEvents.onRtmfpPeerConnect',
		onPeerDisconnectCall:'ChatEvents.onRtmfpPeerDisonnect'};
	
	rtmfp = new Rtmfp("../rtmfp.swf",config);
}

/**
 * 
 */
User = function (nickname,peerId) {
	this.nickName = nickname;
	this.peerId = peerId;
	this.color = randomColor();
}

/**
 * Static variables for room state.
 */
ChatState = function () {
	var pub = {};
	
	pub.addUser = function(user) {
		if(pub.getUserByPeerId(user.peerId) == null) {
			ChatState.listUsers.push(user);
		}
	}
	
	pub.getUserByPeerId = function(peerId) {
		var users = ChatState.listUsers;
		for(var u in users) {
			if(users[u].peerId == peerId)
				return users[u];
		}
		return null;
	}
	
	return pub;
}();

ChatState.isChatOwner = false;
ChatState.connected = false;

ChatState.roomTitle = "";
ChatState.roomId = "";
ChatState.listUsers = [];
ChatState.currentUser = new User("Anonymous");
ChatState.addUser(ChatState.currentUser);


/**
 * Actions
 */
ChatActions = function () {
	var pub = {};
	
	pub.switchToRoom = function(roomTitle) {
		ChatState.roomTitle = roomTitle;
		$("#room_title").text(roomTitle);
		
		if(!ChatState.connected) {
			$("#divDialogConnect").hide();
			$("#section_create").hide();
			$("#section_chat").fadeIn(1500);
			
			$("#overlay").show();
			$("#divDialogNickName").show();
			
			ChatState.connected = true;
			
			ChatUI.showInviteUrl();
		}
	}
	
	pub.createRoom = function(roomName) {
		if(roomName == '')
			roomName = 'Untitled';
		
		ChatState.isChatOwner = true;
		ChatState.roomId = ChatState.currentUser.peerId;
		pub.switchToRoom(roomName);
	}
	
	pub.loadRoom = function(roomId) {
		ChatState.roomId = roomId;
		rtmfp.connectToPeer(roomId);
	}
	
	/** When a regular peer send a message **/
	pub.sendMessage = function(message) {
		
		if(!ChatState.isChatOwner) {
			rtmfp.send("MSG",message);
		}
		else {
			var myId = ChatState.currentUser.peerId;
			pub.broadcastMessage(myId,message);
			ChatUI.printMessage(myId,message);
		}
	}
	
	/** Chat owner broadcast to all peers **/
	pub.broadcastMessage = function(peerId,message) {
		var msg = {};
		msg['peerId'] = peerId;
		msg['message'] = message;
		
		rtmfp.send("MSGB",msg);
	}
	
	pub.changeNickName = function(nickName) {
		if(nickName == '')
			nickName = 'Anonymous';
		
		if(!ChatState.isChatOwner) {
			rtmfp.send("NICK",nickName);
		}
		
		ChatState.currentUser.nickName = nickName;
		ChatUI.updateListUsers();
		
		$("#overlay").hide();
		$("#divDialogNickName").hide();
	}
	
	pub.sendListUsers = function() {
		var listUsers = $.extend(true,[],ChatState.listUsers);
		
		rtmfp.send("USERS",listUsers);
	}
	
	pub.sendRoomTitle = function() {
		rtmfp.send("ROOM",ChatState.roomTitle);
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
		
		//console.info("(JS) New message [cmd]="+cmd+" [data]="+data);
		
		var user = ChatState.getUserByPeerId(peerId);
		
		if(cmd == 'USERS') {
			ChatState.listUsers = data;
			ChatUI.updateListUsers();
		}
		else if(cmd == 'ROOM') {
			ChatActions.switchToRoom(data);
		}
		else if(cmd == 'MSG') {
			ChatUI.printMessage(user.peerId,data);
			if(ChatState.isChatOwner) {
				ChatActions.broadcastMessage(user.peerId,data);
			}
		}
		else if(cmd == 'MSGB') {
			if(!ChatState.isChatOwner) {
				var userMsg = ChatState.getUserByPeerId(data['peerId']);
				ChatUI.printMessage(userMsg.peerId,data['message']);
			}
		}
		else if(cmd == 'NICK') {
			if(data == '')
				data = 'Anonymous';
			
			user.nickName = data;
			ChatUI.updateListUsers();
			ChatActions.sendListUsers();
		}
	}
	
	pub.onRtmfpPeerIdRecv = function(peerId) {
		ChatState.currentUser.peerId = peerId;
		
		if(url_params['room']) {
			ChatActions.loadRoom(url_params['room']);
		}
	}
	
	pub.onRtmfpPeerConnect = function(peerId) {
		//Make sure connection is established
		if(ChatState.isChatOwner) {
			rtmfp.connectToPeer(peerId);
			
			var u = new User("Guest",peerId);
			ChatState.addUser(u);
			ChatActions.sendListUsers();
			ChatActions.sendRoomTitle();
		}
		else {
			
		}
	}
	
	pub.onRtmfpPeerDisconnect = function(peerId) {
		
	}
	
	return pub;
}();

/**
 * Change various UI elements.
 */
ChatUI = function () {
	var pub = {};
	
	pub.printMessage = function (peerId,message) {
		var u = ChatState.getUserByPeerId(peerId);
		$("#divMessages").append("<b style='color:"+escapeHtml(u.color)+"'>"+escapeHtml(u.nickName)+":</b> "+escapeHtml(message)+"<br/>");
		
		$("#divMessages")[0].scrollTop = $("#divMessages")[0].scrollHeight; //Scroll to bottom
	}
	
	pub.printNotice = function(notice) {
		$("#divMessages").append("<i>"+escapeHtml(notice)+"</i>");
	}
	
	pub.updateListUsers = function() {
		var ul = $('ul#ulListPeers').empty();
		
		for(var userIdx in ChatState.listUsers) {
			var user = ChatState.listUsers[userIdx];
			ul.append("<li style='color:"+escapeHtml(user.color)+"'>"+escapeHtml(user.nickName)+"</li>");
		}
	}
	
	pub.showInviteUrl = function() {
		var href=window.location.href+"?";
		hrefCrop = href.slice(0,href.indexOf('?'));
		$("#txtInviteUrl").val(hrefCrop+"?room="+ChatState.roomId);
		$("#divInvite").show();
	}
	
	return pub;
}();

/**
 * Escape special characters
 */
function escapeHtml(someText) {
	return $('<div/>').text(someText).html();
}

function randomColor() {
	var r = Math.floor((Math.random()*160)+40).toString(16);
	var g = Math.floor((Math.random()*160)+40).toString(16);
	var b = Math.floor((Math.random()*160)+40).toString(16);
	
	return '#'+r+g+b;
}

function loadQueryParams() {
	var query = window.location.search;
	var params = [];
	
	var listTmp = query.slice(query.indexOf('?') + 1).split('&');
	for(var h in listTmp) {
	    var split = listTmp[h].split('=');
	    params[split[0]] = split[1];
	}
	return params;
}