require 'spec_helper'

describe SlackInvite::Commands::Set do
  let!(:team) { Fabricate(:team, created_at: 2.weeks.ago) }
  let(:app) { SlackInvite::Server.new(team:) }
  let(:client) { app.send(:client) }
  let(:user) { Fabricate(:user, team:) }

  before do
    allow(User).to receive(:find_create_or_update_by_slack_id!).and_return(user)
  end

  it 'requires a subscription' do
    expect(message: "#{SlackRubyBot.config.user} set approval on").to respond_with_slack_message(team.trial_message)
  end

  context 'subscribed team' do
    let(:team) { Fabricate(:team, subscribed: true) }

    it 'errors on invalid setting' do
      expect(message: "#{SlackRubyBot.config.user} set whatever").to respond_with_slack_message(
        'Invalid setting whatever, type `help` for instructions.'
      )
    end

    it 'shows current settings' do
      expect(message: "#{SlackRubyBot.config.user} set").to respond_with_slack_message([
        "Approval to join team #{team.name} is not required.",
        "Invitations to join team #{team.name} are sent on behalf of your Slack admin."
      ].join("\n"))
    end

    context 'approval' do
      it 'shows default value of approval' do
        expect(message: "#{SlackRubyBot.config.user} set approval").to respond_with_slack_message(
          "Approval to join team #{team.name} is not required."
        )
      end

      it 'shows current value of approval set to true' do
        team.update_attributes!(require_approval: true)
        expect(message: "#{SlackRubyBot.config.user} set approval").to respond_with_slack_message(
          "Approval to join team #{team.name} is required."
        )
      end

      it 'does not change approval' do
        team.update_attributes!(require_approval: true)
        expect(message: "#{SlackRubyBot.config.user} set approval false").to respond_with_slack_message([
          "Approval to join team #{team.name} is required.",
          'Only a Slack admin can change approval, sorry.'
        ].join("\n"))
        expect(team.reload.require_approval).to be true
      end

      context 'admin user' do
        let(:user) { Fabricate(:user, team:, is_admin: true) }

        it 'sets approval to false' do
          team.update_attributes!(require_approval: true)
          expect(message: "#{SlackRubyBot.config.user} set approval false").to respond_with_slack_message(
            "Approval to join team #{team.name} is no longer required."
          )
          expect(team.reload.require_approval).to be false
        end

        context 'with approval set to false' do
          before do
            team.update_attributes!(require_approval: false)
          end

          it 'sets approval to true' do
            expect(message: "#{SlackRubyBot.config.user} set approval true").to respond_with_slack_message(
              "Approval to join team #{team.name} is now required."
            )
            expect(team.reload.require_approval).to be true
          end
        end
      end
    end

    context 'sender' do
      it 'shows default value of sender' do
        expect(message: "#{SlackRubyBot.config.user} set sender").to respond_with_slack_message(
          "Invitations to join team #{team.name} are sent on behalf of your Slack admin."
        )
      end

      it 'shows admin sender' do
        team.update_attributes!(admin_user: user)
        expect(message: "#{SlackRubyBot.config.user} set sender").to respond_with_slack_message(
          "Invitations to join team #{team.name} are sent on behalf of #{user.user_name}."
        )
      end

      context 'with another user' do
        let!(:user2) { Fabricate(:user, team:) }

        it 'does not change sender' do
          team.update_attributes!(admin_user: user)
          expect(message: "#{SlackRubyBot.config.user} set sender #{user2.slack_mention}").to respond_with_slack_message([
            "Invitations to join team #{team.name} are sent on behalf of #{user.user_name}.",
            'Only a Slack admin can change who sends invitations, sorry.'
          ].join("\n"))
          expect(team.reload.admin_user).to eq user
        end

        context 'admin user' do
          let(:user) { Fabricate(:user, team:, is_admin: true) }
          let(:admin_user) { Fabricate(:user, team:, is_admin: true) }

          it 'sets sender' do
            team.update_attributes!(admin_user: user)
            expect_any_instance_of(User).to receive(:dm_auth_request!)
            expect(message: "#{SlackRubyBot.config.user} set sender #{admin_user.slack_mention}").to respond_with_slack_message(
              "I've DMed #{admin_user.user_name} for authorization."
            )
          end

          it 'requires an admin user' do
            team.update_attributes!(admin_user: user)
            expect_any_instance_of(User).not_to receive(:dm_auth_request!)
            expect(message: "#{SlackRubyBot.config.user} set sender #{user2.slack_mention}").to respond_with_slack_message(
              "User #{user2.user_name} must be a Slack admin."
            )
          end

          it 'shows sender' do
            team.update_attributes!(admin_user: user2)
            expect(message: "#{SlackRubyBot.config.user} set sender #{user2.slack_mention}").to respond_with_slack_message(
              "Invitations to join team #{team.name} are sent on behalf of #{user2.user_name}."
            )
          end
        end
      end
    end
  end
end
