class Team
  field :api, type: Boolean, default: false
  field :require_approval, type: Boolean, default: false

  field :stripe_customer_id, type: String
  field :subscribed, type: Boolean, default: false
  field :subscribed_at, type: DateTime
  field :subscription_expired_at, type: DateTime

  field :trial_informed_at, type: DateTime

  field :admin_token, type: String
  belongs_to :admin_user, class_name: 'User', inverse_of: nil, index: true, optional: true

  scope :api, -> { where(api: true) }
  scope :striped, -> { where(subscribed: true, :stripe_customer_id.ne => nil) }
  scope :trials, -> { where(subscribed: false) }

  has_many :users, dependent: :destroy
  has_many :invitations, dependent: :destroy

  before_validation :update_subscription_expired_at
  after_update :inform_subscribed_changed!
  after_save :inform_activated!

  def asleep?(dt = 2.weeks)
    return false unless subscription_expired?
    time_limit = Time.now - dt
    created_at <= time_limit
  end

  def slack_client
    @slack_client ||= Slack::Web::Client.new(token: token)
  end

  def admin_slack_client
    raise 'Missing admin token, please authorize a user.' unless admin_token
    @admin_slack_client ||= Slack::Web::Client.new(token: admin_token)
  end

  def slack_channels
    slack_client.channels_list(
      exclude_archived: true,
      exclude_members: true
    )['channels'].select do |channel|
      channel['is_member']
    end
  end

  # returns channels that were sent to
  def inform!(message)
    slack_channels.map do |channel|
      message_with_channel = message.merge(channel: channel['id'], as_user: true)
      logger.info "Posting '#{message_with_channel.to_json}' to #{self} on ##{channel['name']}."
      rc = slack_client.chat_postMessage(message_with_channel)

      {
        ts: rc['ts'],
        channel: channel['id']
      }
    end
  end

  # returns DM channel
  def inform_admin!(message)
    return unless activated_user_id
    channel = slack_client.im_open(user: activated_user_id)
    message_with_channel = message.merge(channel: channel.channel.id, as_user: true)
    logger.info "Sending DM '#{message_with_channel.to_json}' to #{activated_user_id}."
    rc = slack_client.chat_postMessage(message_with_channel)

    {
      ts: rc['ts'],
      channel: channel.channel.id
    }
  end

  def inform_everyone!(message)
    inform!(message)
    inform_admin!(message)
  end

  def subscription_expired!
    return unless subscription_expired?
    return if subscription_expired_at
    inform_everyone!(text: subscribe_text)
    update_attributes!(subscription_expired_at: Time.now.utc)
  end

  def subscription_expired?
    return false if subscribed?
    time_limit = Time.now - 2.weeks
    created_at < time_limit
  end

  def subscribe_text
    [trial_expired_text, subscribe_team_text].compact.join(' ')
  end

  def invite_link
    "#{SlackRubyBotServer::Service.url}/invite?team_id=#{team_id}"
  end

  def invite_text
    if admin_token
      "Your users can join at #{invite_link}."
    else
      'Please use `/invitebot setup` next.'
    end
  end

  def update_cc_text
    "Update your credit card info at #{SlackRubyBotServer::Service.url}/update_cc?team_id=#{team_id}."
  end

  def subscribed_text
    <<~EOS.freeze
      Your team has been subscribed. Thank you!
      Follow https://twitter.com/playplayio for news and updates.
EOS
  end

  def trial_ends_at
    raise 'Team is subscribed.' if subscribed?
    created_at + 2.weeks
  end

  def remaining_trial_days
    raise 'Team is subscribed.' if subscribed?
    [0, (trial_ends_at.to_date - Time.now.utc.to_date).to_i].max
  end

  def trial_message
    [
      remaining_trial_days.zero? ? 'Your trial subscription has expired.' : "Your trial subscription expires in #{remaining_trial_days} day#{remaining_trial_days == 1 ? '' : 's'}.",
      subscribe_team_text
    ].join(' ')
  end

  def inform_trial!
    return if subscribed? || subscription_expired?
    return if trial_informed_at && (Time.now.utc < trial_informed_at + 7.days)
    inform_everyone!(text: trial_message)
    update_attributes!(trial_informed_at: Time.now.utc)
  end

  def tags
    [
      subscribed? ? 'subscribed' : 'trial',
      stripe_customer_id? ? 'paid' : nil
    ].compact
  end

  private

  def trial_expired_text
    return unless subscription_expired?
    'Your trial subscription has expired.'
  end

  def subscribe_team_text
    "Subscribe your team for $9.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team_id}."
  end

  def inform_subscribed_changed!
    return unless subscribed? && subscribed_changed?
    inform_everyone!(text: subscribed_text)
  end

  def bot_mention
    "<@#{bot_user_id || 'invitebot'}>"
  end

  def activated_text
    <<~EOS
      Welcome to Slack Invite Automation!
      Use `/invitebot help` to get more information.
EOS
  end

  def inform_activated!
    return unless active? && activated_user_id && bot_user_id
    return unless active_changed? || activated_user_id_changed?

    im = slack_client.im_open(user: activated_user_id)
    slack_client.chat_postMessage(
      text: activated_text,
      channel: im['channel']['id'],
      as_user: true
    )

    user = User.find_create_or_update_by_team_and_slack_id!(team_id, activated_user_id)
    user.dm_auth_request!
  end

  def update_subscription_expired_at
    self.subscription_expired_at = nil if subscribed || subscribed_at
  end
end
