require 'spec_helper'

describe Api::Endpoints::InvitationsEndpoint do
  include Api::Test::EndpointTest

  context 'invitations' do
    let!(:team) { Fabricate(:team, admin_token: 'token') }
    let!(:admin) { Fabricate(:user, team: team, is_admin: true) }
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
    context 'with approval' do
      before do
        team.update_attributes!(require_approval: true)
      end
      it 'queues a invitation and DMs an admin' do
        expect_any_instance_of(Slack::Web::Client).to_not receive(:users_admin_invite)
        expect_any_instance_of(User).to receive(:dm!)
        expect {
          client.invitations._post(
            team_id: team.team_id,
            email: 'email@example.com'
          )
        }.to change(team.invitations, :count).by(1)
      end
    end
  end
end
