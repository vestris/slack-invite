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
            { message: command.team.subscribe_text }
          else
            #             case command.action
            #             # when TODO
            #             else
            #             end
            { message: "Sorry, I don't understand the `#{command.callback_id}` command." }
          end
        end
      end
    end
  end
end
