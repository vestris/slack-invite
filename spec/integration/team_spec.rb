require 'spec_helper'

describe 'Teams', :js, type: :feature do
  before do
    ENV['SLACK_CLIENT_ID'] = 'client_id'
    ENV['SLACK_CLIENT_SECRET'] = 'client_secret'
  end

  after do
    ENV.delete 'SLACK_CLIENT_ID'
    ENV.delete 'SLACK_CLIENT_SECRET'
  end

  context 'oauth', vcr: { cassette_name: 'auth_test' } do
    context 'with team_info', vcr: { cassette_name: 'slack/team_info' } do
      it 'registers a team' do
        allow_any_instance_of(Team).to receive(:ping!).and_return(ok: true)
        expect(SlackRubyBotServer::Service.instance).to receive(:start!)
        oauth_access = { 'bot' => { 'bot_access_token' => 'token' }, 'team_id' => 'team_id',
                         'team_name' => 'team_name' }
        allow_any_instance_of(Slack::Web::Client).to receive(:oauth_access).with(hash_including(code: 'code')).and_return(oauth_access)
        expect {
          visit '/?code=code'
          expect(page.find_by_id('messages')).to have_content 'Team successfully registered!'
        }.to change(Team, :count).by(1)
        team = Team.asc(:_id).last
        expect(team.team_id).to eq 'team_id'
        expect(team.domain).to eq 'dblockdotorg'
        expect(team.icon).to eq 'https://s3-us-west-2.amazonaws.com/slack-files2/avatars/2015-04-28/4657218807_d480d2ee610d2e8aacfe_132.jpg'
        expect(team.workspace_url).to eq 'https://dblockdotorg.slack.com'
      end
    end
  end

  context 'homepage' do
    before do
      visit '/'
    end

    it 'displays index.html page' do
      expect(title).to eq('Slack Invite Automation: User Workflow in Slack')
    end

    it 'includes a link to add to slack with the client id' do
      expect(first("a[href='https://slack.com/oauth/authorize?scope=bot,commands&client_id=#{ENV.fetch(
        'SLACK_CLIENT_ID', nil
      )}']"))
    end
  end
end
