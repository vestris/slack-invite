function invite(event) {
  event.preventDefault();

  var name = $('#name').val();
  var email = $('#email').val();
  var team_id = $.url('?team_id')

  SlackInvite.message('Working, please wait ...');

  $('#form').fadeOut('slow', function() {
    $.ajax({
      type: "POST",
      url: "/api/invitations",
      data: {
        name: name,
        email: email,
        team_id: team_id
      },
      success: function(data) {
        SlackInvite.message('Invitation ' + data.status + '!');
      },
      error: SlackInvite.error
    });
  });
} 
