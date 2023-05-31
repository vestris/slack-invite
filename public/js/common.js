var SlackInvite = {};

$(document).ready(function() {

  SlackInvite.message = function(text) {
    $('#messages').removeClass('has-error');
    $('#messages').fadeOut('slow', function() {
      $('#messages').fadeIn('slow').html(text)
    });
  };

  SlackInvite.register = function(text) {
    $('.navbar').fadeOut('slow');
    $('header').fadeOut('slow');
    $('section').fadeOut('slow');
    $('#register').show();
  };

  SlackInvite.errorMessage = function(message) {
    SlackInvite.message(message)
    $('#messages').addClass('has-error');
  };

  SlackInvite.error = function(xhr) {
    var message;
    if (xhr.responseText) {
      var rc = JSON.parse(xhr.responseText);
      if (rc && rc.error) {
        message = rc.error;
      } else if (rc && rc.message) {
        message = rc.message;
        if (message == 'invalid_code') {
          message = 'The code returned from the OAuth workflow was invalid.'
        } else if (message == 'code_already_used') {
          message = 'The code returned from the OAuth workflow has already been used.'
        }
      }
    }
    if (message == "already_in_team") {
      message = "You have already joined this Slack workspace. Open it using the link above.";
    }

    SlackInvite.errorMessage(message || xhr.statusText || xhr.responseText || 'Unexpected Error');
  };
});
