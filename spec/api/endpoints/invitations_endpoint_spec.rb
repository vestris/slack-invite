require 'spec_helper'

describe Api::Endpoints::InvitationsEndpoint do
  include Api::Test::EndpointTest

  context 'invitations' do
    let!(:team) { Fabricate(:team, admin_token: 'token') }
    let!(:admin) { Fabricate(:user, team:, is_admin: true) }
    let(:email) { Faker::Internet.email }

    it 'creates a invitation' do
      expect_any_instance_of(Slack::Web::Client).to receive(:users_admin_invite).with(
        real_name: nil,
        email:
      )
      expect {
        client.invitations._post(
          team_id: team.team_id,
          email:
        )
      }.to change(team.invitations, :count).by(1)
    end

    context 'with approval' do
      before do
        team.update_attributes!(require_approval: true)
      end

      it 'queues a invitation and DMs an admin' do
        expect_any_instance_of(Slack::Web::Client).not_to receive(:users_admin_invite)
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
