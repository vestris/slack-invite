function invite(event) {
  event.preventDefault();

  var email = $('#email').val();
  var team_id = $.url('?team_id')

  SlackInvite.message('Working, please wait ...');

  $('#form').fadeOut('slow', function() {
    $.ajax({
      type: "POST",
      url: "/api/invitations",
      data: {
        email: email,
        team_id: team_id
      },
      success: function(data) {
        SlackInvite.message('Invitation successfully requested!<br><br>Stay tuned.');
      },
      error: SlackInvite.error
    });
  });
} 
