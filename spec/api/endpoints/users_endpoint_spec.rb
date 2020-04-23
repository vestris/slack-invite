require 'spec_helper'

describe Api::Endpoints::UsersEndpoint do
  include Api::Test::EndpointTest

  context 'users' do
    let(:user) { Fabricate(:user) }
    it 'authorizes a user' do
      expect_any_instance_of(User).to receive(:authorize!).with('code')
      client.user(id: user.id)._put(code: 'code')
    end
    it 'assigns an access token' do
      access = { 'access_token' => 'token', 'team_id' => user.team.team_id }
      expect_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(hash_including(code: 'code')).and_return(access)
      expect_any_instance_of(User).to receive(:dm!).with(
        text: [
          'Authorized!',
          "Your users can join at https://invite.playplay.io/invite?team_id=#{user.team.team_id}.",
          'For more information use `/invitebot help`.'
        ].join("\n")
      )
      client.user(id: user.id)._put(code: 'code')
      expect(user.reload.access_token).to eq 'token'
      expect(user.team.admin_token).to eq 'token'
      expect(user.team.admin_user).to eq user
    end
    it 'verifies team' do
      access = { 'access_token' => 'token', 'team_name' => 'Team Name', 'team_id' => 'invalid' }
      expect_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(hash_including(code: 'code')).and_return(access)
      expect {
        client.user(id: user.id)._put(code: 'code')
      }.to raise_error Faraday::ClientError do |e|
        json = JSON.parse(e.response[:body])
        expect(json['message']).to eq "Please choose team \"#{user.team.name}\" instead of \"Team Name\"."
      end
      expect(user.reload.access_token).to be nil
    end
  end
end
