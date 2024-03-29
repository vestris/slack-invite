require 'spec_helper'

describe 'Invite', js: true, type: :feature do
  context 'request an invitation' do
    before do
      allow_any_instance_of(Team).to receive(:update_team_info!)
    end
    context 'without a team id' do
      it 'displays an error' do
        visit '/invite'
        expect(page.find('#messages')).to have_content 'Missing or invalid team ID.'
      end
    end
    context 'with a team having a quote in the name' do
      let!(:team) { Fabricate(:team, name: "dblock's team") }
      it 'displays team name' do
        visit "/invite?team_id=#{team.team_id}"
        expect(page.find('#team_name')).to have_content "dblock's team"
      end
    end
    context 'with a team' do
      let!(:team) { Fabricate(:team, admin_token: 'token') }
      it 'displays team info' do
        visit "/invite?team_id=#{team.team_id}"
        expect(page.find('#team_name')).to have_content team.name
        expect(page.find('#team_href')).to have_content team.workspace_url
        expect(page).to have_link team.workspace_url, href: team.workspace_url
        expect(page.find('#team_icon')['src']).to have_content team.icon
      end
      it 'sends an invitation' do
        expect_any_instance_of(Slack::Web::Client).to receive(:users_admin_invite).with(
          email: 'email@example.com'
        )
        expect {
          visit "/invite?team_id=#{team.team_id}"
          fill_in 'name', with: Faker::Name.name
          fill_in 'email', with: 'email@example.com'
          click_on 'Submit'
          expect(page.find('#messages')).to have_content 'Invitation sent!'
        }.to change(team.invitations, :count).by(1)
      end
      it 'displays already a member' do
        expect_any_instance_of(Slack::Web::Client).to receive(:users_admin_invite).and_raise(Slack::Web::Api::Errors::SlackError, 'already_in_team')
        expect {
          visit "/invite?team_id=#{team.team_id}"
          fill_in 'name', with: Faker::Name.name
          fill_in 'email', with: 'email@example.com'
          click_on 'Submit'
          expect(page.find('#messages')).to have_content 'Already a team member.'
        }.to change(team.invitations, :count).by(1)
      end
      context 'with approval' do
        let!(:admin) { Fabricate(:user, is_admin: true, team: team) }
        before do
          team.update_attributes!(require_approval: true)
        end
        it 'queues a invitation and DMs an admin' do
          expect_any_instance_of(Slack::Web::Client).to_not receive(:users_admin_invite)
          expect_any_instance_of(User).to receive(:dm!)
          expect {
            visit "/invite?team_id=#{team.team_id}"
            fill_in 'name', with: Faker::Name.name
            fill_in 'email', with: 'email@example.com'
            click_on 'Submit'
            expect(page.find('#messages')).to have_content 'Invitation requested!'
          }.to change(team.invitations, :count).by(1)
        end
        context 'with an existing invitation' do
          let!(:invitation) { Fabricate(:invitation, team: team, ignored_at: Time.now.utc) }
          it 'ignores the invitation' do
            expect_any_instance_of(Slack::Web::Client).to_not receive(:users_admin_invite)
            expect {
              visit "/invite?team_id=#{team.team_id}"
              fill_in 'name', with: invitation.name
              fill_in 'email', with: invitation.email
              click_on 'Submit'
              expect(page.find('#messages')).to have_content 'Invitation ignored!'
            }.to_not change(team.invitations, :count)
          end
        end
      end
    end
  end
end
