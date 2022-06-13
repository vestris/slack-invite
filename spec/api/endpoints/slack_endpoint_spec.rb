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
            text: team.subscribe_text
          }.to_json)
        end
      end
      context 'an invitation' do
        let(:invitation) { Fabricate(:invitation, team: team) }
        it 'approves' do
          expect_any_instance_of(Invitation).to receive(:approve!)
          post '/api/slack/action', payload: {
            actions: [{ name: 'approve', value: invitation.id.to_s }],
            user: { id: user.user_id },
            team: { id: team.team_id },
            channel: { id: 'C1', name: 'invite' },
            token: token,
            callback_id: 'invitation'
          }.to_json
          expect(last_response.status).to eq 201
          expect(last_response.body).to eq(invitation.to_slack.to_json)
        end
        it 'ignores' do
          expect_any_instance_of(Invitation).to receive(:ignore!)
          post '/api/slack/action', payload: {
            actions: [{ name: 'ignore', value: invitation.id.to_s }],
            user: { id: user.user_id },
            team: { id: team.team_id },
            channel: { id: 'C1', name: 'invite' },
            token: token,
            callback_id: 'invitation'
          }.to_json
          expect(last_response.status).to eq 201
          expect(last_response.body).to eq(invitation.to_slack.to_json)
        end
        it 'handles already_in_team' do
          allow_any_instance_of(Invitation).to receive(:approve!).and_raise(Slack::Web::Api::Errors::SlackError,
                                                                            'already_in_team')
          post '/api/slack/action', payload: {
            actions: [{ name: 'approve', value: invitation.id.to_s }],
            user: { id: user.user_id },
            team: { id: team.team_id },
            channel: { id: 'C1', name: 'invite' },
            token: token,
            callback_id: 'invitation'
          }.to_json
          expect(last_response.status).to eq 201
          expect(last_response.body).to eq({ text: "User #{invitation.name_and_email} is already a member of the team." }.to_json)
        end
        it 'handles already_invited' do
          allow_any_instance_of(Invitation).to receive(:approve!).and_raise(Slack::Web::Api::Errors::SlackError,
                                                                            'already_invited')
          post '/api/slack/action', payload: {
            actions: [{ name: 'approve', value: invitation.id.to_s }],
            user: { id: user.user_id },
            team: { id: team.team_id },
            channel: { id: 'C1', name: 'invite' },
            token: token,
            callback_id: 'invitation'
          }.to_json
          expect(last_response.status).to eq 201
          expect(last_response.body).to eq({ text: "User #{invitation.name_and_email} has already been invited." }.to_json)
        end
        it 'handles other errors' do
          allow_any_instance_of(Invitation).to receive(:approve!).and_raise(Slack::Web::Api::Errors::SlackError,
                                                                            'invite_limit_reached')
          post '/api/slack/action', payload: {
            actions: [{ name: 'approve', value: invitation.id.to_s }],
            user: { id: user.user_id },
            team: { id: team.team_id },
            channel: { id: 'C1', name: 'invite' },
            token: token,
            callback_id: 'invitation'
          }.to_json
          expect(last_response.status).to eq 201
          expect(last_response.body).to eq({ text: 'invite_limit_reached' }.to_json)
        end
      end
    end
    after do
      ENV.delete('SLACK_VERIFICATION_TOKEN')
    end
  end
end
