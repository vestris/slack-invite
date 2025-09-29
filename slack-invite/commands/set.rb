module SlackInvite
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackInvite::Commands::Mixins::Subscribe

      subscribe_command 'set' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        team = Team.find(client.owner.id)
        if match['expression']
          k, v = match['expression'].split(/[\s,.]/, 2).reject(&:blank?)
          case k
          when 'sender'
            v = ::User.find_by_slack_mention!(client, v) if v
            changed = v && team.admin_user != v
            if v && !user.is_admin
              client.say(channel: data.channel, text: [
                "Invitations to join team #{team.name} are sent on behalf of #{team.admin_user&.user_name || 'your Slack admin'}.",
                changed ? 'Only a Slack admin can change who sends invitations, sorry.' : nil
              ].compact.join("\n"))
            elsif changed && v
              if v.is_admin?
                v.dm_auth_request!
                client.say(channel: data.channel, text: "I've DMed #{v.user_name} for authorization.")
                logger.info "SENDER: #{team}, user=#{data.user} - DMed #{v} for authorization."
              else
                client.say(channel: data.channel, text: "User #{v.user_name} must be a Slack admin.")
                logger.info "SENDER: #{team}, user=#{data.user} - #{v} is not a Slack admin."
              end
            else
              client.say(channel: data.channel,
                         text: "Invitations to join team #{team.name} are sent on behalf of #{team.admin_user&.user_name || 'your Slack admin'}.")
            end
          when 'approval'
            changed = v && team.require_approval != v
            if changed && !user.is_admin
              client.say(channel: data.channel, text: [
                "Approval to join team #{team.name} is #{'not ' unless team.require_approval?}required.",
                'Only a Slack admin can change approval, sorry.'
              ].join("\n"))
            else
              team.update_attributes!(require_approval: v) unless v.nil?
              client.say(channel: data.channel,
                         text: "Approval to join team #{team.name} is #{if changed
                                                                          team.require_approval? ? 'now ' : 'no longer '
                                                                        else
                                                                          (team.require_approval? ? '' : 'not ')
                                                                        end}required.")
            end
            logger.info "SET: #{team}, user=#{data.user} - require_approval set to #{team.require_approval}"
          else
            raise "Invalid setting #{k}, type `help` for instructions."
          end
        else
          messages = [
            "Approval to join team #{team.name} is #{'not ' unless team.require_approval?}required.",
            "Invitations to join team #{team.name} are sent on behalf of #{team.admin_user&.user_name || 'your Slack admin'}."
          ]
          client.say(channel: data.channel, text: messages.join("\n"))
          logger.info "SET: #{team}, user=#{data.user} - set"
        end
      end
    end
  end
end
