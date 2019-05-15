require 'spec_helper'

describe 'Invite', js: true, type: :feature do
  context 'request an invitation' do
    context 'without a team id' do
      it 'displays an error' do
        visit '/invite'
        expect(page.find('#messages')).to have_content 'Missing or invalid team ID.'
      end
    end
    context 'with a team' do
      let!(:team) { Fabricate(:team, admin_token: 'token') }
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
