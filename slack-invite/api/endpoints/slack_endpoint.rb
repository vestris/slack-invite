require_relative 'command'

module Api
  module Endpoints
    class SlackEndpoint < Grape::API
      format :json

      namespace :slack do
        desc 'Respond to slash commands.'
        params do
          requires :command, type: String
          requires :text, type: String
          requires :token, type: String
          requires :user_id, type: String
          requires :channel_id, type: String
          requires :channel_name, type: String
          requires :team_id, type: String
        end
        post '/command' do
          command = SlackEndpointCommands::Command.new(params)
          command.slack_verification_token!

          response = if command.team.subscription_expired?
                       { text: command.team.subscribe_text }
                     else
                       case command.action
                       when 'setup' then
                         command.user.to_slack_auth_request
                       else
                         { text: "Sorry, I don't understand the `#{command.action}` command." }
                       end
          end

          response.merge(response_type: 'ephemeral')
        end

        desc 'Respond to interactive slack buttons and actions.'
        params do
          requires :payload, type: JSON do
            requires :token, type: String
            requires :callback_id, type: String
            optional :type, type: String
            optional :trigger_id, type: String
            optional :response_url, type: String
            requires :channel, type: Hash do
              requires :id, type: String
              optional :name, type: String
            end
            requires :user, type: Hash do
              requires :id, type: String
              optional :name, type: String
            end
            requires :team, type: Hash do
              requires :id, type: String
              optional :domain, type: String
            end
            optional :actions, type: Array do
              requires :name, type: String
              requires :value, type: String
            end
            optional :message, type: Hash do
              requires :type, type: String
              requires :user, type: String
              requires :ts, type: String
              requires :text, type: String
            end
          end
        end
        post '/action' do
          command = SlackEndpointCommands::Command.new(params)
          command.slack_verification_token!

          if command.team.subscription_expired?
            { text: command.team.subscribe_text }
          else
            case command.action
            when 'invitation'
              invitation = command.team.invitations.where(_id: command.arg).first
              raise 'missing invitation' unless invitation

              case command.name
              when 'ignore' then
                invitation.ignore!(command.user)
                invitation.to_slack
              when 'approve' then
                begin
                  invitation.approve!(command.user)
                  invitation.to_slack
                rescue Slack::Web::Api::Errors::SlackError => e
                  case e.message
                  when 'already_invited' then
                    { text: "User #{invitation.name_and_email} has already been invited." }
                  when 'already_in_team_invited_user', 'already_in_team' then
                    { text: "User #{invitation.name_and_email} is already a member of the team." }
                  else
                    { text: e.message }
                  end
                end
              else
                { text: "Sorry, I don't understand the `#{command.action}##{command.name}` command." }
              end
            else
              { text: "Sorry, I don't understand the `#{command.action}` command." }
            end
          end
        rescue StandardError => e
          { text: e.message }
        end
      end
    end
  end
end
