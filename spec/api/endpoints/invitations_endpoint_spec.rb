require 'spec_helper'

describe Api::Endpoints::InvitationsEndpoint do
  include Api::Test::EndpointTest

  context 'invitations' do
    let!(:team) { Fabricate(:team) }
    it 'creates a invitation' do
      expect_any_instance_of(Slack::Web::Client).to receive(:users_admin_invite).with(
        email: 'email@example.com'
      )
      expect {
        client.invitations._post(
          team_id: team.team_id,
          email: 'email@example.com'
        )
      }.to change(team.invitations, :count).by(1)
    end
  end
end
