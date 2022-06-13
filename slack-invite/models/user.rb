class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :access_token, type: String

  field :is_bot, type: Boolean, default: false
  field :is_admin, type: Boolean, default: false

  belongs_to :team, index: true
  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)

  scope :admins, -> { where(is_admin: true) }

  def slack_mention
    "<@#{user_id}>"
  end

  def self.slack_mention?(user_name)
    slack_id = ::Regexp.last_match[1] if user_name =~ /^<[@!](.*)>$/
    slack_id = nil if %w[here channel].include?(slack_id)
    slack_id
  end

  def self.find_by_slack_mention!(client, user_name)
    team = client.owner
    slack_id = slack_mention?(user_name)
    user = if slack_id
             team.users.where(user_id: slack_id).first
           else
             regexp = ::Regexp.new("^#{user_name}$", 'i')
             User.where(team: team, user_name: regexp).first
           end
    unless user
      begin
        users_info = client.web_client.users_info(user: slack_id || "@#{user_name}")
        info = Hashie::Mash.new(users_info).user if users_info
        if info
          user = User.create!(
            team: team,
            user_id: info.id,
            user_name: info.name,
            is_admin: info.is_admin,
            is_bot: info.is_bot
          )
        end
      rescue Slack::Web::Api::Errors::SlackError => e
        raise e unless e.message == 'user_not_found'
      end
    end
    raise SlackInvite::Error, "I don't know who #{user_name} is!" unless user

    user
  end

  def self.find_create_or_update_by_team_and_slack_id!(team_id, user_id)
    team = Team.where(team_id: team_id).first || raise("Cannot find team ID #{team_id}")
    User.where(team: team, user_id: user_id).first || User.create!(team: team, user_id: user_id)
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(client, slack_id)
    instance = User.where(team: client.owner, user_id: slack_id).first
    instance_info = Hashie::Mash.new(client.web_client.users_info(user: slack_id)).user
    if instance && instance.is_admin != instance_info.is_admin
      instance.update_attributes!(is_admin: instance_info.is_admin)
    end
    instance.update_attributes!(is_bot: instance_info.is_bot) if instance && instance.is_bot != instance_info.is_bot
    instance.update_attributes!(user_name: instance_info.name) if instance && instance.user_name != instance_info.name
    instance ||= User.create!(
      team: client.owner,
      user_id: slack_id,
      user_name: instance_info.name,
      is_bot: instance_info.is_bot,
      is_admin: instance_info.is_admin
    )
    instance
  end

  def inform!(message)
    team.slack_channels.map { |channel|
      next if user_id && !user_in_channel?(channel['id'])

      message_with_channel = message.merge(channel: channel['id'], as_user: true)
      logger.info "Posting '#{message_with_channel.to_json}' to #{team} on ##{channel['name']}."
      rc = team.slack_client.chat_postMessage(message_with_channel)

      {
        ts: rc['ts'],
        channel: channel['id']
      }
    }.compact
  end

  def dm!(message)
    im = team.slack_client.conversations_open(users: user_id.to_s)
    team.slack_client.chat_postMessage(message.merge(channel: im['channel']['id'], as_user: true))
  end

  def dm_auth_request!
    dm!(to_slack_auth_request)
  end

  def authorized_text
    [
      'Authorized!',
      team.invite_text,
      'For more information use `/invitebot help`.'
    ].compact.join("\n")
  end

  def authorize!(code)
    rc = team.slack_client.oauth_access(
      client_id: ENV.fetch('SLACK_CLIENT_ID', nil),
      client_secret: ENV.fetch('SLACK_CLIENT_SECRET', nil),
      code: code,
      redirect_uri: authorize_uri
    )

    unless rc['team_id'] == team.team_id
      raise SlackInvite::Error,
            "Please choose team \"#{team.name}\" instead of \"#{rc['team_name']}\"."
    end

    update_attributes!(access_token: rc['access_token'])

    team.update_attributes!(admin_user: self, admin_token: rc['access_token'])

    dm!(text: authorized_text)
  end

  def to_s
    "user_id=#{user_id}, user_name=#{user_name}"
  end

  def authorize_uri
    "#{SlackRubyBotServer::Service.url}/authorize"
  end

  def slack_oauth_url
    "https://slack.com/oauth/authorize?scope=admin,client&client_id=#{ENV.fetch('SLACK_CLIENT_ID',
                                                                                nil)}&redirect_uri=#{URI.encode(authorize_uri)}&team=#{team.team_id}&state=#{id}"
  end

  def to_slack_auth_request
    {
      text: 'Please authorize your account to send user invites.',
      attachments: [
        fallback: slack_oauth_url,
        actions: [
          type: 'button',
          text: 'Authorize',
          url: slack_oauth_url
        ]
      ]
    }
  end
end
