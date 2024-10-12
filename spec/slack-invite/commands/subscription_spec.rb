require 'spec_helper'

describe SlackInvite::Commands::Subscription, vcr: { cassette_name: 'slack/user_info' } do
  let(:app) { SlackInvite::Server.new(team:) }
  let(:client) { app.send(:client) }

  context 'team' do
    let!(:team) { Fabricate(:team) }

    it 'is a subscription feature' do
      expect(message: "#{SlackRubyBot.config.user} subscription", user: 'user').to respond_with_slack_message(
        "Your trial subscription has expired. Subscribe your team for $9.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team.team_id}."
      )
    end
  end

  context 'active, not a subscriber' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago, stripe_customer_id: nil) }

    it 'errors' do
      expect(message: "#{SlackRubyBot.config.user} subscription", user: 'user').to respond_with_slack_message(
        "Not a subscriber. Subscribe your team for $9.99 a year at #{SlackRubyBotServer::Service.url}/subscribe?team_id=#{team.team_id}."
      )
    end
  end

  context 'active, subscribed = true' do
    let!(:team) { Fabricate(:team, created_at: 1.day.ago, subscribed: true) }

    it 'is lucky' do
      expect(message: "#{SlackRubyBot.config.user} subscription", user: 'user').to respond_with_slack_message(
        'Subscribed, free account. Lucky you!'
      )
    end
  end

  shared_examples_for 'subscription' do
    include_context 'stripe mock'
    context 'with a plan' do
      before do
        stripe_helper.create_plan(id: 'invite-yearly', amount: 999)
      end

      context 'a customer' do
        let!(:customer) do
          Stripe::Customer.create(
            source: stripe_helper.generate_card_token,
            plan: 'invite-yearly',
            email: 'foo@bar.com'
          )
        end

        before do
          team.update_attributes!(subscribed: true, stripe_customer_id: customer['id'])
        end

        it 'displays subscription info' do
          customer_info = "Customer since #{Time.at(customer.created).strftime('%B %d, %Y')}."
          customer_info += "\nSubscribed to StripeMock Default Plan ID ($9.99)"
          card = customer.sources.first
          customer_info += "\nOn file Visa card, #{card.name} ending with #{card.last4}, expires #{card.exp_month}/#{card.exp_year}."
          customer_info += "\n#{team.update_cc_text}"
          expect(message: "#{SlackRubyBot.config.user} subscription").to respond_with_slack_message customer_info
        end
      end
    end
  end

  context 'subscription team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    it_behaves_like 'subscription'
    context 'with another team' do
      let!(:team2) { Fabricate(:team) }

      it_behaves_like 'subscription'
    end
  end
end
