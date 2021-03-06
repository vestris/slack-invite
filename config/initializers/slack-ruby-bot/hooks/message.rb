module SlackRubyBot
  module Hooks
    class Message
      # HACK: order command classes predictably
      def command_classes
        [
          SlackInvite::Commands::Help,
          SlackInvite::Commands::Info,
          SlackInvite::Commands::Subscription,
          SlackInvite::Commands::Set
        ]
      end
    end
  end
end
