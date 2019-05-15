class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :user_id, type: String
  field :user_name, type: String
  field :access_token, type: String

  field :is_bot, type: Boolean, default: false

  belongs_to :team, index: true
  validates_presence_of :team

  index({ user_id: 1, team_id: 1 }, unique: true)
  index(user_name: 1, team_id: 1)

  def slack_mention
    "<@#{user_id}>"
  end

  def self.find_by_slack_mention!(team, user_name)
    query = user_name =~ /^<@(.*)>$/ ? { user_id: ::Regexp.last_match[1] } : { user_name: ::Regexp.new("^#{user_name}$", 'i') }
    user = User.where(query.merge(team: team)).first
    raise SlackInvite::Error, "I don't know who #{user_name} is!" unless user
    user
  end

  def self.find_create_or_update_by_team_and_slack_id!(team_id, user_id)
    team = Team.where(team_id: team_id).first || raise("Cannot find team ID #{team_id}")
    user = User.where(team: team, user_id: user_id).first || User.create!(team: team, user_id: user_id)
    user
  end

  # Find an existing record, update the username if necessary, otherwise create a user record.
  def self.find_create_or_update_by_slack_id!(client, slack_id)
    instance = User.where(team: client.owner, user_id: slack_id).first
    instance_info = Hashie::Mash.new(client.web_client.users_info(user: slack_id)).user
    instance.update_attributes!(user_name: instance_info.name, is_bot: instance_info.is_bot) if instance && (instance.user_name != instance_info.name || instance.is_bot != instance_info.is_bot)
    instance ||= User.create!(team: client.owner, user_id: slack_id, user_name: instance_info.name, is_bot: instance_info.is_bot)
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
    im = team.slack_client.im_open(user: user_id)
    team.slack_client.chat_postMessage(message.merge(channel: im['channel']['id'], as_user: true))
  end

  def authorize!(code)
    rc = team.slack_client.oauth_access(
      client_id: ENV['SLACK_CLIENT_ID'],
      client_secret: ENV['SLACK_CLIENT_SECRET'],
      code: code,
      redirect_uri: authorize_uri
    )

    raise SlackInvite::Error, "Please choose team \"#{team.name}\" instead of \"#{rc['team_name']}\"." unless rc['team_id'] == team.team_id

    update_attributes!(access_token: rc['access_token'])

    team.update_attributes!(admin_token: rc['access_token'])

    dm!(text: "Authorized!\nFor more information use `/invitebot help`.")
  end

  def to_s
    "user_id=#{user_id}, user_name=#{user_name}"
  end

  def authorize_uri
    "#{SlackRubyBotServer::Service.url}/authorize"
  end

  def slack_oauth_url
    "https://slack.com/oauth/authorize?scope=admin,client&client_id=#{ENV['SLACK_CLIENT_ID']}&redirect_uri=#{URI.encode(authorize_uri)}&team=#{team.team_id}&state=#{id}"
  end

  def to_slack_auth_request
    {
      text: 'Please authorize admin.',
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
