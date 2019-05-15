$(document).ready(function() {
  // Slack OAuth
  var code = $.url('?code')
  if (code) {
    SlackInvite.register();
    SlackInvite.message('Working, please wait ...');
    $.ajax({
      type: "POST",
      url: "/api/teams",
      data: {
        code: code
      },
      success: function(data) {
        SlackInvite.message('Team successfully registered!<br><br>Try <b>/invitebot me</b> to add invitebot to your profile.');
      },
      error: SlackInvite.error
    });
  }
});