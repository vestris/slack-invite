require 'spec_helper'

describe User do
  context '#find_by_slack_mention!' do
    let!(:user) { Fabricate(:user) }
    it 'finds by slack id' do
      expect(User.find_by_slack_mention!(user.team, "<@#{user.user_id}>")).to eq user
    end
    it 'finds by username' do
      expect(User.find_by_slack_mention!(user.team, user.user_name)).to eq user
    end
    it 'finds by username is case-insensitive' do
      expect(User.find_by_slack_mention!(user.team, user.user_name.capitalize)).to eq user
    end
    it 'requires a known user' do
      expect {
        User.find_by_slack_mention!(user.team, '<@nobody>')
      }.to raise_error SlackInvite::Error, "I don't know who <@nobody> is!"
    end
  end
  context '#find_create_or_update_by_slack_id!', vcr: { cassette_name: 'slack/user_info' } do
    let!(:team) { Fabricate(:team) }
    let(:client) { SlackRubyBot::Client.new }
    before do
      client.owner = team
    end
    context 'without a user' do
      it 'creates a user' do
        expect {
          user = User.find_create_or_update_by_slack_id!(client, 'whatever')
          expect(user).to_not be_nil
          expect(user.user_id).to eq 'whatever'
          expect(user.user_name).to eq 'username'
        }.to change(User, :count).by(1)
      end
    end
    context 'with a user' do
      let!(:user) { Fabricate(:user, team: team) }
      it 'creates another user' do
        expect {
          User.find_create_or_update_by_slack_id!(client, 'whatever')
        }.to change(User, :count).by(1)
      end
      it 'updates the username of the existing user' do
        expect {
          User.find_create_or_update_by_slack_id!(client, user.user_id)
        }.to_not change(User, :count)
        expect(user.reload.user_name).to eq 'username'
      end
    end
  end
  context '#authorize!' do
    let!(:user) { Fabricate(:user) }
    it 'retrieves a slack access token' do
      expect(user.team.slack_client).to receive(:oauth_access).with(
        client_id: nil,
        client_secret: nil,
        code: 'code',
        redirect_uri: '/authorize'
      ).and_return(
        'access_token' => 'access-token',
        'team_id' => user.team.team_id
      )
      expect(user).to receive(:dm!).with(
        text: "Authorized!\nFor more information use `/invitebot help`."
      )
      user.authorize!('code')
      expect(user.access_token).to eq 'access-token'
    end
  end
end
