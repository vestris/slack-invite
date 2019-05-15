module SlackInvite
  module Commands
    class Help < SlackRubyBot::Commands::Base
      HELP = <<~EOS.freeze
        ```
        Slack Invite Automation

        Commands
        --------
        /invitebot setup         - initial setup

        DM
        --
        help                     - get this helpful message
        subscription             - show subscription info
        info                     - bot info
        ```
EOS
      def self.call(client, data, _match)
        client.say(channel: data.channel, text: [
          HELP,
          client.owner.invite_text,
          client.owner.reload.subscribed? ? nil : client.owner.subscribe_text
        ].compact.join("\n"))
        logger.info "HELP: #{client.owner}, user=#{data.user}"
      end
    end
  end
end
