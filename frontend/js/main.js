var WS_SERVER_URL = 'ws://localhost:8080';

var letterNode = document.getElementsByClassName('b-letter')[0];
var lastLetter = '';

function setLetter(l) {
    if (l != lastLetter) {
        lastLetter = l;
        letterNode.innerHTML = l.toUpperCase();
    }
}

function eraseLetter() {
    letterNode.innerHTML = '&mdash;';
    lastLetter = '';
}

var $statusNode = $('.b-status');

function setOnline() {
    $statusNode.removeClass('label-default');
    $statusNode.addClass('label-success');
    $statusNode.text('online');
}

function setOffline() {
    eraseLetter();
    $statusNode.removeClass('label-success');
    $statusNode.addClass('label-default');
    $statusNode.text('offline');
}

var socket = new WebSocket(WS_SERVER_URL);

socket.onopen = function() {
    setOnline();
};

socket.onclose = function(event) {
    if (event.wasClean) {
        console.log('close was clean');
    } else {
        console.error('socket aborted')
    }
    setOffline();
};

socket.onmessage = function(event) {
    setLetter(event.data);
};

socket.onerror = function(error) {
    console.error("socket error: " + error.message);
};
