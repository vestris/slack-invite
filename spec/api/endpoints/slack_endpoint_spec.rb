require 'spec_helper'

describe Api::Endpoints::SlackEndpoint do
  include Api::Test::EndpointTest

  context 'with a SLACK_VERIFICATION_TOKEN' do
    let(:token) { 'slack-verification-token' }
    let(:team) { Fabricate(:team, subscribed: true) }
    let(:user) { Fabricate(:user, team: team) }
    before do
      ENV['SLACK_VERIFICATION_TOKEN'] = token
    end
    context 'slash commands' do
      it 'returns an error with a non-matching verification token' do
        post '/api/slack/command',
             command: '/invite',
             text: 'me',
             channel_id: 'C1',
             channel_name: 'channel',
             user_id: 'user_id',
             team_id: 'team_id',
             token: 'invalid-token'
        expect(last_response.status).to eq 401
        response = JSON.parse(last_response.body)
        expect(response['error']).to eq 'Message token is not coming from Slack.'
      end
      it 'generates a setup link' do
        post '/api/slack/command',
             command: '/invitebot',
             text: 'setup',
             channel_id: 'C1',
             channel_name: 'channel',
             user_id: user.user_id,
             team_id: user.team.team_id,
             token: token
        expect(last_response.status).to eq 201
        expect(last_response.body).to eq(user.to_slack_auth_request.merge(response_type: 'ephemeral').to_json)
      end
      it 'errors on all other commands' do
        post '/api/slack/command',
             command: '/invitebot',
             text: 'foobar',
             channel_id: 'C1',
             channel_name: 'channel',
             user_id: user.user_id,
             team_id: user.team.team_id,
             token: token
        expect(last_response.status).to eq 201
        expect(last_response.body).to eq({
          text: "Sorry, I don't understand the `foobar` command.",
          response_type: 'ephemeral'
        }.to_json)
      end
      context 'subscription expired' do
        let(:team) { Fabricate(:team, subscribed: false) }
        it 'errors' do
          post '/api/slack/command',
               command: '/invite',
               text: 'me',
               channel_id: 'C1',
               channel_name: 'channel',
               user_id: user.user_id,
               team_id: user.team.team_id,
               token: token
          expect(last_response.status).to eq 201
          expect(last_response.body).to eq({
            text: team.subscribe_text,
            response_type: 'ephemeral'
          }.to_json)
        end
      end
    end
    context 'interactive buttons' do
      context 'subscription expired' do
        let(:team) { Fabricate(:team, subscribed: false) }
        it 'errors' do
          post '/api/slack/action', payload: {
            type: 'message_action',
            user: { id: user.user_id },
            team: { id: team.team_id },
            channel: { id: 'C1', name: 'invite' },
            message_ts: '1547654324.000400',
            message: { text: 'I love it when a dog barks.', type: 'text', user: 'U04KB5WQR', ts: '1547654324.000400' },
            token: token,
            callback_id: 'whatever'
          }.to_json
          expect(last_response.status).to eq 201
          expect(last_response.body).to eq({
            message: team.subscribe_text
          }.to_json)
        end
      end
    end
    after do
      ENV.delete('SLACK_VERIFICATION_TOKEN')
    end
  end
end
