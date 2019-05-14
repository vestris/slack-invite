module Api
  module Endpoints
    class SlackEndpointCommands
      class Command
        attr_reader :action, :arg, :channel_id, :channel_name, :user_id, :team_id, :text, :image_url, :token, :response_url, :trigger_id, :type, :submission, :message_ts

        def initialize(params)
          if params.key?(:payload)
            payload = params[:payload]
            @action = payload[:callback_id]
            @channel_id = payload[:channel][:id]
            @channel_name = payload[:channel][:name]
            @user_id = payload[:user][:id]
            @team_id = payload[:team][:id]
            @type = payload[:type]
            @message_ts = payload[:message_ts]
            if params[:payload].key?(:actions)
              @arg = payload[:actions][0][:value]
              @text = [action, arg].join(' ')
            elsif params[:payload].key?(:message)
              payload_message = payload[:message]
              @text = payload_message[:text]
              @message_ts ||= payload_message[:ts]
              if payload_message.key?(:attachments)
                payload_message[:attachments].each do |attachment|
                  @text = [@text, attachment[:image_url]].compact.join("\n")
                end
              end
            end
            @token = payload[:token]
            @response_url = payload[:response_url]
            @trigger_id = payload[:trigger_id]
            @submission = payload[:submission]
          else
            @text = params[:text]
            @action, @arg = text.split(/\s/, 2)
            @channel_id = params[:channel_id]
            @channel_name = params[:channel_name]
            @user_id = params[:user_id]
            @team_id = params[:team_id]
            @token = params[:token]
          end
        end

        def user
          @user ||= ::User.find_create_or_update_by_team_and_slack_id!(
            team_id,
            user_id
          )
        end

        def team
          user&.team
        end

        def slack_verification_token!
          return unless ENV.key?('SLACK_VERIFICATION_TOKEN')
          return if token == ENV['SLACK_VERIFICATION_TOKEN']

          throw :error, status: 401, message: 'Message token is not coming from Slack.'
        end
      end
    end
  end
end
