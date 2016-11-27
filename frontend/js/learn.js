var ML_SEVER_URL = 'http://localhost:8000/?set_letter=';
var STOP_LEARNING_SYMBOL = '.';

function setLetter(letter) {
    $.get(ML_SEVER_URL + letter)
        .error(function (err) {
            console.error('new letter: ' + err);
        })
        .done(function () {
            console.log('letter changed to ' + letter);
        });
}

$('.b-set-letter').click(function() {
    var newLetter = $('.b-letter').val();
    if (/^[a-zA-Z]+$/.test(newLetter)) {
        setLetter(newLetter);
    }
});


$('.b-stop-learning').click(function() {
    setLetter(STOP_LEARNING_SYMBOL);
});


