module SlackInvite
  module Commands
    class Set < SlackRubyBot::Commands::Base
      include SlackInvite::Commands::Mixins::Subscribe

      subscribe_command 'set' do |client, data, match|
        user = ::User.find_create_or_update_by_slack_id!(client, data.user)
        team = client.owner
        if !match['expression']
          messages = [
            "Approval to join team #{team.name} is #{team.require_approval? ? '' : 'not '}required."
          ]
          client.say(channel: data.channel, text: messages.join("\n"))
          logger.info "SET: #{team}, user=#{data.user} - set"
        else
          k, v = match['expression'].split(/\W+/, 2)
          case k
          when 'approval' then
            changed = v && team.require_approval != v
            if changed && !user.is_admin
              client.say(channel: data.channel, text: [
                "Approval to join team #{team.name} is #{team.require_approval? ? '' : 'not '}required.",
                'Only a Slack admin can change that, sorry.'
              ].join("\n"))
            else
              team.update_attributes!(require_approval: v) unless v.nil?
              client.say(channel: data.channel, text: "Approval to join team #{team.name} is #{changed ? (team.require_approval? ? 'now ' : 'no longer ') : (team.require_approval? ? '' : 'not ')}required.")
            end
            logger.info "SET: #{team}, user=#{data.user} - require_approval set to #{team.require_approval}"
          else
            raise "Invalid setting #{k}, type `help` for instructions."
          end
        end
      end
    end
  end
end
