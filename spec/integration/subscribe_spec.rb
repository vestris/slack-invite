require 'spec_helper'

describe 'Subscribe', :js, type: :feature do
  context 'without team_id' do
    before do
      visit '/subscribe'
    end

    it 'requires a team' do
      expect(find_by_id('messages')).to have_text('Missing or invalid team ID.')
      find_by_id('subscribe', visible: false)
    end
  end

  context 'for a subscribed team' do
    let!(:team) { Fabricate(:team, subscribed: true) }

    before do
      visit "/subscribe?team_id=#{team.team_id}"
    end

    it 'displays an error' do
      expect(find_by_id('messages')).to have_text("Team #{team.name} is already subscribed, thank you for your support.")
      find_by_id('subscribe', visible: false)
    end
  end

  shared_examples 'subscribes' do
    it 'subscribes' do
      visit "/subscribe?team_id=#{team.team_id}"
      expect(find_by_id('messages')).to have_text("Subscribe team #{team.name} for $9.99/yr.")
      find_by_id('subscribe', visible: true)

      expect(Stripe::Customer).to receive(:create).and_return('id' => 'customer_id')

      find_by_id('subscribeButton').click
      sleep 1

      expect_any_instance_of(Team).to receive(:inform!).with(text: team.subscribed_text)

      stripe_iframe = all('iframe[name=stripe_checkout_app]').last
      Capybara.within_frame stripe_iframe do
        page.find_field('Email').set 'foo@bar.com'
        page.find_field('Card number').client_set '4242 4242 4242 4242'
        page.find_field('MM / YY').client_set '12/42'
        page.find_field('CVC').set '123'
        find('button[type="submit"]').click
      end

      sleep 5

      expect(find_by_id('messages')).to have_text("Team #{team.name} successfully subscribed.\n\nThank you for your support!")
      find_by_id('subscribe', visible: false)

      team.reload
      expect(team.subscribed).to be true
      expect(team.stripe_customer_id).to eq 'customer_id'
    end
  end

  context 'with a stripe key' do
    before do
      ENV['STRIPE_API_PUBLISHABLE_KEY'] = 'pk_test_804U1vUeVeTxBl8znwriXskf'
    end

    after do
      ENV.delete 'STRIPE_API_PUBLISHABLE_KEY'
    end

    context 'a team' do
      let!(:team) { Fabricate(:team) }

      it_behaves_like 'subscribes'
    end
  end
end
