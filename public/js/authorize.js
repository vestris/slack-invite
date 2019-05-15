$(document).ready(function() {
  // Slack OAuth for a user
  var code = $.url('?code')
  var id = $.url('?state')
  if (code && id) {
    SlackInvite.message('Working, please wait ...');
    $.ajax({
      type: "PUT",
      url: "/api/users/" + id,
      data: {
        code: code
      },
      success: function(data) {
        SlackInvite.message('User successfully authorized!');
      },
      error: SlackInvite.error
    });
  }
});