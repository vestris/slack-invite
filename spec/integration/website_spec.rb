require 'spec_helper'

describe 'Website', :js, type: :feature do
  it 'opens and closes approval instructions with the keyboard' do
    visit '/help.html'
    background = page.evaluate_script('getComputedStyle(document.body, "::before").height')
    within('details', text: 'Can an admin approve each request?') do
      expect(page).to have_no_css('p')
      find('summary').send_keys(:enter)
      expect(page).to have_css('p', text: 'set approval on')
      expect(page.evaluate_script('getComputedStyle(document.body, "::before").position')).to eq 'fixed'
      expect(page.evaluate_script('getComputedStyle(document.body, "::before").height')).to eq background
      find('summary').send_keys(:enter)
      expect(page).to have_no_css('p')
    end
  end

  it 'keeps navigation usable at 320 pixels' do
    visit '/'
    page.execute_script("document.body.innerHTML = '<iframe id=\"mobile\" title=\"Mobile\" src=\"/\" width=\"320\" style=\"border:0\"></iframe>'")
    within_frame('mobile') do
      expect(page.evaluate_script('window.innerWidth')).to eq 320
      expect(page).to have_link('Slack Invite Automation', href: '/')
      expect(page).to have_css('html') { |html| html.evaluate_script('this.scrollWidth <= window.innerWidth') }
      within('nav') { click_link 'Help' }
      expect(page).to have_css('h1', text: 'A little help getting people in.')
      all('details > summary').each(&:click)
      expect(page).to have_css('html') { |html| html.evaluate_script('this.scrollWidth <= window.innerWidth') }
    end
  end

  it 'keeps FAQ screenshots at their original display sizes' do
    visit '/help.html'
    all('details > summary').each(&:click)
    all('.help-topic img').each do |image|
      expect(image).to match_css('img') do |rendered|
        rendered.evaluate_script('this.getBoundingClientRect().width === (this.classList.contains("invitation-preview") ? 640 : 400)')
      end
    end
  end

  it 'keeps OAuth registration visible without the homepage' do
    visit '/'
    page.execute_script('SlackInvite.register()')
    expect(page).to have_no_css('#homepage')
    expect(page).to have_css('#register #messages', text: 'Please wait')
    expect(page).to have_link('Get help', href: '/help.html#support')
  end
end
